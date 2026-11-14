<?php

/*
 * Copyright (c) 2026 jk8s and jk-ufw contributors
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

namespace OPNsense\JkUfw\Api;

use OPNsense\Base\ApiMutableModelControllerBase;
use OPNsense\Base\UserException;
use OPNsense\Base\ValidationException;
use OPNsense\Core\Backend;
use OPNsense\Core\Config;
use OPNsense\Firewall\Alias;
use OPNsense\Firewall\Filter;
use OPNsense\JkUfw\AppControl;

/**
 * jk-ufw application control API (/api/jkufw/appcontrol/*).
 *
 * apply() does two things:
 *   1. firewall objects for what works without the IPS: aliases jkufw_appctl_* and floating reject rules tagged
 *      "[jk-ufw app]" for DNS over HTTPS/TLS/QUIC resolvers and for QUIC (UDP 443)
 *   2. starts scripts/jkufw/appcontrol.py in the background, which writes the Suricata rules (applications,
 *      category names in the TLS handshake, DoH names) and reloads Suricata; status() reports its progress
 */
class AppcontrolController extends ApiMutableModelControllerBase
{
    protected static $internalModelClass = '\OPNsense\JkUfw\AppControl';
    protected static $internalModelName = 'appcontrol';

    /**
     * Applications, their categories and the web filter categories, for the page.
     */
    public function catalogAction()
    {
        $cat = AppControl::catalog();
        $apps = [];
        foreach ($cat['apps'] as $app) {
            $how = [];
            if (!empty($app['sni'])) {
                $how[] = ['kind' => 'sni', 'items' => $app['sni']];
            }
            if (!empty($app['ip'])) {
                $how[] = ['kind' => 'ip', 'items' => $app['ip']];
            }
            if (!empty($app['proto'])) {
                $how[] = ['kind' => 'proto', 'items' => $app['proto']];
            }
            if (!empty($app['ports'])) {
                $how[] = ['kind' => 'ports', 'items' => array_map(fn($p) => strtoupper($p['proto']) . ' ' . str_replace(':', '–', $p['port']), $app['ports'])];
            }
            if (!empty($app['sig'])) {
                $how[] = ['kind' => 'sig', 'items' => [count($app['sig'])]];
            }
            $apps[] = ['id' => $app['id'], 'name' => $app['name'], 'cat' => $app['cat'], 'color' => $app['color'] ?? '#888', 'how' => $how];
        }
        return [
            'categories' => $cat['categories'],
            'apps' => $apps,
            'web' => array_map(fn($c) => ['id' => $c['id'], 'name' => $c['name']], $cat['web']['categories']),
            'doh' => ['names' => count($cat['doh']['sni']), 'addresses' => count($cat['doh']['ip'])]
        ];
    }

    /**
     * Engine state (Suricata settings and service), progress of the last apply, and usage in the last 24 hours.
     */
    public function statusAction()
    {
        $backend = new Backend();
        $result = json_decode($backend->configdRun('jkufw appcontrol.status') ?? '', true) ?: ['state' => [], 'stats' => []];
        $cfg = Config::getInstance()->object();
        $ids = $cfg->OPNsense->IDS->general ?? null;
        $ifaces = $ids !== null ? array_values(array_filter(explode(',', (string)$ids->interfaces))) : [];
        $names = [];
        $lan = [];
        foreach (isset($cfg->interfaces) ? $cfg->interfaces->children() : [] as $key => $node) {
            $names[$key] = !empty((string)$node->descr) ? (string)$node->descr : strtoupper($key);
            /* interfaces with a local network behind them: candidates for the sensor */
            if ($key != 'wan' && !empty((string)$node->enable) && !empty((string)$node->ipaddr) && empty((string)$node->gateway)) {
                $lan[] = $key;
            }
        }
        $running = strpos($backend->configdRun('ids status') ?? '', 'is running') !== false;
        $mode = $ids !== null ? (string)$ids->mode : 'pcap';
        $result['ids'] = [
            'enabled' => $ids !== null && (string)$ids->enabled == '1',
            'running' => $running,
            'mode' => $mode,
            'ips' => $mode !== 'pcap' && $mode !== '',
            'interfaces' => array_map(fn($k) => ['id' => $k, 'name' => $names[$k] ?? $k], $ifaces),
            'lan' => array_map(fn($k) => ['id' => $k, 'name' => $names[$k] ?? $k], $lan),
            'on_lan' => count(array_intersect($ifaces, $lan)) > 0
        ];
        $hosts = [];
        foreach (isset($cfg->dhcpd) ? $cfg->dhcpd->children() : [] as $node) {
            foreach ($node->staticmap as $map) {
                if (!empty((string)$map->ipaddr)) {
                    $hosts[(string)$map->ipaddr] = (string)($map->hostname ?: $map->descr);
                }
            }
        }
        $result['hostnames'] = $hosts;
        return $result;
    }

    public function applyAction()
    {
        if (!$this->request->isPost()) {
            return ['status' => 'failed'];
        }
        Config::getInstance()->lock();
        $this->throwReadOnly();
        try {
            $this->sync();
        } catch (ValidationException $e) {
            throw new UserException($e->getMessage(), gettext('Application control'));
        }
        Config::getInstance()->save();
        $backend = new Backend();
        $status = trim($backend->configdRun('filter reload'));
        /* the rule generator may download category lists first: run it in the background, the page polls status */
        $backend->configdRun('jkufw appcontrol.apply', true);
        return ['status' => $status === '' ? 'OK' : $status];
    }

    private function sync()
    {
        $mdl = $this->getModel();
        $cat = AppControl::catalog();
        $tag = AppControl::RULE_TAG;
        $exempt = array_values(array_filter(explode(',', (string)$mdl->exempt)));
        $doh = !empty((string)$mdl->block_doh);
        $quic = !empty((string)$mdl->block_quic);

        $want = [];
        if ($doh) {
            $want[AppControl::DOH_ALIAS] = ['type' => 'host', 'content' => $cat['doh']['ip'],
                'description' => 'jk-ufw: public DNS over HTTPS/TLS resolvers'];
            $want[AppControl::DOH_ALIAS . 'list'] = ['type' => 'urltable', 'content' => $cat['doh']['lists'], 'updatefreq' => '1',
                'description' => 'jk-ufw: DNS over HTTPS resolvers (community list, daily)'];
            $want[AppControl::DOH_ALIAS . 'ports'] = ['type' => 'port', 'content' => ['443', '853', '8853'],
                'description' => 'jk-ufw: DNS over HTTPS, TLS and QUIC ports'];
        }
        if (($doh || $quic) && !empty($exempt)) {
            $want[AppControl::PREFIX . 'exempt'] = ['type' => 'network', 'content' => $exempt,
                'description' => 'jk-ufw: devices left out of application control'];
        }

        /* 1. aliases: add or update ours */
        $aliases = new Alias();
        $have = [];
        foreach ($aliases->aliases->alias->iterateItems() as $uuid => $alias) {
            if (str_starts_with((string)$alias->name, AppControl::PREFIX)) {
                $have[(string)$alias->name] = $uuid;
            }
        }
        foreach ($want as $name => $def) {
            $node = isset($have[$name]) ? $aliases->getNodeByReference('aliases.alias.' . $have[$name]) : $aliases->aliases->alias->Add();
            unset($have[$name]);
            $node->enabled = '1';
            $node->name = $name;
            $node->type = $def['type'];
            $node->content = implode("\n", $def['content']);
            $node->description = $def['description'];
            if (isset($def['updatefreq'])) {
                $node->updatefreq = $def['updatefreq'];
            }
        }
        $aliases->serializeToConfig();

        /* 2. floating rules */
        $filter = new Filter();
        $remove = [];
        foreach ($filter->rules->rule->iterateItems() as $uuid => $rule) {
            if (str_starts_with((string)$rule->description, $tag)) {
                $remove[] = $uuid;
            }
        }
        foreach ($remove as $uuid) {
            $filter->rules->rule->del($uuid);
        }
        $base = [
            'enabled' => '1', 'action' => 'reject', 'quick' => '1', 'interface' => '', 'direction' => 'in',
            'ipprotocol' => 'inet46', 'protocol' => 'TCP/UDP', 'destination_not' => '0', 'sched' => '', 'log' => '1',
            'source_net' => empty($exempt) ? 'any' : AppControl::PREFIX . 'exempt', 'source_not' => empty($exempt) ? '0' : '1',
        ];
        $seq = 5;
        if ($doh) {
            foreach (['', 'list'] as $suffix) {
                $filter->rules->rule->Add()->setNodes(array_merge($base, [
                    'sequence' => (string)$seq++, 'destination_net' => AppControl::DOH_ALIAS . $suffix,
                    'destination_port' => AppControl::DOH_ALIAS . 'ports',
                    'description' => "{$tag} DNS over HTTPS/TLS resolver blocked" . ($suffix ? ' (list)' : ''),
                ]));
            }
        }
        if ($quic) {
            $filter->rules->rule->Add()->setNodes(array_merge($base, [
                'sequence' => (string)$seq++, 'protocol' => 'UDP', 'destination_net' => '(self)', 'destination_not' => '1',
                'destination_port' => '443', 'log' => '0', 'description' => "{$tag} QUIC (HTTP/3) blocked, browsers use HTTPS",
            ]));
        }
        $filter->serializeToConfig();

        /* 3. stale aliases, now unreferenced */
        if (!empty($have)) {
            foreach ($have as $uuid) {
                $aliases->aliases->alias->del($uuid);
            }
            $aliases->serializeToConfig();
        }
    }
}
