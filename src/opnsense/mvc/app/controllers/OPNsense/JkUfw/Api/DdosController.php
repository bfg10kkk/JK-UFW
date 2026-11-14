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
use OPNsense\Base\FieldTypes\BaseListField;
use OPNsense\Base\UserException;
use OPNsense\Base\ValidationException;
use OPNsense\Core\Backend;
use OPNsense\Core\Config;
use OPNsense\Core\Tunables;
use OPNsense\Firewall\Alias;
use OPNsense\Firewall\DNat;
use OPNsense\Firewall\Filter;
use OPNsense\JkUfw\Ddos;

/**
 * jk-ufw attack protection API (/api/jkufw/ddos/*).
 *
 * get                 settings
 * save (POST)         all settings at once: general, interfaces[], ioc {custom, log, feeds[]}, siem[]
 * status              interfaces with their rules, pf statistics, blocked addresses, history, events, feeds
 * apply (POST)        turn the settings into firewall objects (see below) and reload what changed
 * block / unblock     put an address on / take it off the automatic block list (POST {address})
 * siemtest (POST)     send a test event to a log collector (POST {uuid})
 *
 * What apply does, everything recorded in "applied" so it can be put back exactly:
 *  - pass rules on a protected interface that are open to everyone (source "any") get per-address limits:
 *    max-src-states; TCP rules also max-src-conn, max-src-conn-rate with overload <jkufw_ddos_block>
 *    and, at the strict level, synproxy. Fields the user filled in are left alone.
 *  - one floating block rule per feature: [jk-ufw ddos] blocks the overload table and the deny list on the
 *    protected interfaces, [jk-ufw ioc] blocks threat feed addresses in both directions on all interfaces.
 *  - pf SYN cookies, adaptive timeouts, optimization (System > Settings > Firewall), ICMP / RST answer limit
 *    (tunable net.inet.icmp.icmplim), bogon blocking on the protected interfaces.
 *  - a syslog-ng file for the SIEM targets (template OPNsense/JkUfw/Siem).
 * Each apply first puts the previous changes back, then applies the current settings.
 */
class DdosController extends ApiMutableModelControllerBase
{
    protected static $internalModelClass = '\OPNsense\JkUfw\Ddos';
    protected static $internalModelName = 'ddos';

    const GENERAL = ['enabled', 'preset', 'syncookies', 'adaptive', 'optimization', 'icmplimit', 'bogons', 'blocktime', 'allow', 'deny'];
    const IFACE = ['interface', 'enabled', 'level', 'states', 'conns', 'rate', 'per', 'synproxy'];
    const FEED = ['enabled', 'name', 'url', 'refresh'];
    const TARGET = ['enabled', 'name', 'host', 'port', 'transport', 'format', 'logs'];
    /* rule fields this feature may fill in */
    const RULE_FIELDS = ['max-src-states', 'max-src-conn', 'max-src-conn-rate', 'max-src-conn-rates', 'overload', 'statetype'];

    private static function only($data, $keys)
    {
        $result = [];
        foreach ($keys as $k) {
            if (is_array($data) && array_key_exists($k, $data)) {
                $result[$k] = is_array($data[$k]) ? implode(',', $data[$k]) : (string)$data[$k];
            }
        }
        return $result;
    }

    /**
     * replace the items of an ArrayField by a posted list, keeping the uuid of items that carry one
     */
    private static function syncArray($field, $items, $keys)
    {
        $keep = [];
        foreach (is_array($items) ? $items : [] as $item) {
            $uuid = is_array($item) ? ($item['uuid'] ?? '') : '';
            $node = null;
            if ($uuid !== '') {
                foreach ($field->iterateItems() as $id => $n) {
                    if ($id === $uuid) {
                        $node = $n;
                    }
                }
            }
            if ($node === null) {
                $node = $field->Add();
            }
            $node->setNodes(self::only($item, $keys));
            $keep[$node->getAttributes()['uuid']] = true;
        }
        foreach (array_keys(iterator_to_array($field->iterateItems())) as $id) {
            if (!isset($keep[$id])) {
                $field->del($id);
            }
        }
    }

    public function saveAction()
    {
        if (!$this->request->isPost()) {
            return ['result' => 'failed'];
        }
        $data = $this->request->getPost('ddos');
        if (!is_array($data)) {
            return ['result' => 'failed'];
        }
        Config::getInstance()->lock();
        $this->throwReadOnly();
        $mdl = $this->getModel();
        if (isset($data['general'])) {
            $mdl->general->setNodes(self::only($data['general'], self::GENERAL));
        }
        if (isset($data['interfaces'])) {
            self::syncArray($mdl->interfaces->interface, $data['interfaces'], self::IFACE);
        }
        if (isset($data['ioc'])) {
            $mdl->ioc->setNodes(self::only($data['ioc'], ['custom', 'log']));
            if (isset($data['ioc']['feeds'])) {
                self::syncArray($mdl->ioc->feed, $data['ioc']['feeds'], self::FEED);
            }
        }
        if (isset($data['siem'])) {
            self::syncArray($mdl->siem->target, $data['siem'], self::TARGET);
        }
        $result = $this->validate();
        if (empty($result['result'])) {
            $result = $this->save();
        }
        return $result;
    }

    /**
     * hash of the settings, to tell whether they changed since the last apply
     */
    private function settingsHash()
    {
        $nodes = $this->getModel()->getNodes();
        unset($nodes['applied']);
        return md5(json_encode($nodes));
    }

    private function applied()
    {
        $data = json_decode((string)$this->getModel()->applied, true);
        return is_array($data) ? $data : [];
    }

    /**
     * pass rules a protected interface would limit: [uuid => rule node]
     */
    private static function openRules($filter, $ifname)
    {
        $result = [];
        foreach ($filter->rules->rule->iterateItems() as $uuid => $rule) {
            if (
                (string)$rule->enabled == '1' && (string)$rule->action == 'pass' && (string)$rule->direction == 'in' &&
                in_array($ifname, explode(',', (string)$rule->interface), true) &&
                (string)$rule->source_net == 'any' && (string)$rule->source_not != '1' &&
                (string)$rule->statetype != 'none' &&
                !str_starts_with((string)$rule->description, Ddos::RULE_TAG) &&
                !str_starts_with((string)$rule->description, Ddos::IOC_TAG)
            ) {
                $result[$uuid] = $rule;
            }
        }
        return $result;
    }

    private static function isTcp($rule)
    {
        return strtoupper((string)$rule->protocol) === 'TCP';
    }

    public function statusAction()
    {
        $cfg = Config::getInstance()->object();
        $mdl = $this->getModel();
        $backend = new Backend();
        $stats = json_decode($backend->configdRun('jkufw_ddos stats'), true) ?? [];
        $applied = $this->applied();
        $filter = new Filter();

        $own = [];
        foreach ($mdl->interfaces->interface->iterateItems() as $uuid => $node) {
            $own[(string)$node->interface] = ['uuid' => $uuid, 'enabled' => (string)$node->enabled == '1',
                'level' => (string)$node->level, 'limits' => Ddos::limits($node)];
        }

        /* port forwards that pass by themselves ("rdr pass"): no filter rule, so no limits */
        $rdrpass = [];
        foreach ((new DNat())->rule->iterateItems() as $rule) {
            if ((string)$rule->disabled != '1' && in_array((string)$rule->pass, ['pass', 'rule'], true)) {
                foreach (explode(',', (string)$rule->interface) as $if) {
                    $rdrpass[$if] = ($rdrpass[$if] ?? 0) + 1;
                }
            }
        }

        $ifs = [];
        foreach ($cfg->interfaces->children() as $ifname => $if) {
            if (empty((string)$if->enable) || $ifname == 'lo0' || (string)$if->type == 'group') {
                continue;
            }
            $ipaddr = (string)$if->ipaddr;
            $wan = in_array($ipaddr, ['dhcp', 'pppoe', 'pptp', 'l2tp', 'ppp'], true) || (string)$if->gateway !== '';
            $open = self::openRules($filter, $ifname);
            $limited = 0;
            foreach (array_keys($open) as $uuid) {
                if (!empty($applied['rules'][$uuid])) {
                    $limited++;
                }
            }
            $rules = [];
            foreach ($open as $uuid => $rule) {
                $rules[] = [
                    'uuid' => $uuid,
                    'description' => (string)$rule->description,
                    'protocol' => (string)$rule->protocol,
                    'destination' => (string)$rule->destination_net,
                    'port' => (string)$rule->destination_port,
                    'tcp' => self::isTcp($rule),
                    'limited' => !empty($applied['rules'][$uuid]),
                ];
            }
            $ifs[] = [
                'name' => $ifname,
                'descr' => (string)$if->descr ?: strtoupper($ifname),
                'device' => (string)$if->if,
                'address' => filter_var($ipaddr, FILTER_VALIDATE_IP) ? $ipaddr . '/' . (string)$if->subnet : $ipaddr,
                'private' => filter_var($ipaddr, FILTER_VALIDATE_IP) &&
                    !filter_var($ipaddr, FILTER_VALIDATE_IP, FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE),
                'wan' => $wan,
                'protected' => !empty($own[$ifname]['enabled']),
                'level' => $own[$ifname]['level'] ?? null,
                'limits' => $own[$ifname]['limits'] ?? null,
                'rules' => $rules,
                'limited' => $limited,
                'rdrpass' => $rdrpass[$ifname] ?? 0,
                'packets' => $stats['interfaces'][$ifname] ?? null,
            ];
        }

        $feeds = [];
        foreach ($mdl->ioc->feed->iterateItems() as $uuid => $feed) {
            $alias = Ddos::IOC_PREFIX . substr(str_replace('-', '', $uuid), 0, 8);
            $feeds[] = ['uuid' => $uuid, 'alias' => $alias, 'entries' => $stats['tables'][$alias] ?? null];
        }

        return [
            'enabled' => (string)$mdl->general->enabled == '1',
            'applied' => !empty($applied['time']),
            'applied_time' => $applied['time'] ?? null,
            'pending' => ($applied['hash'] ?? '') !== $this->settingsHash(),
            'admin_address' => $_SERVER['REMOTE_ADDR'] ?? null,
            'interfaces' => $ifs,
            'feeds' => $feeds,
            'custom_entries' => $stats['tables'][Ddos::IOC_PREFIX . 'custom'] ?? null,
            'stats' => $stats,
            'presets' => Ddos::PRESETS,
            'levels' => Ddos::LEVELS,
            'catalog' => Ddos::FEEDS,
        ];
    }

    public function applyAction()
    {
        if (!$this->request->isPost()) {
            return ['status' => 'failed'];
        }
        Config::getInstance()->lock();
        $this->throwReadOnly();
        $mdl = $this->getModel();
        $old = $this->applied();
        $new = ['time' => time(), 'rules' => [], 'system' => [], 'interfaces' => [], 'tunable' => null];
        $tunableTouched = !empty($old['tunable']);
        try {
            $this->restoreSystem($old);
            $this->syncAliases();
            Config::getInstance()->save();
            $prop = new \ReflectionProperty(BaseListField::class, 'internalStaticOptList');
            $prop->setAccessible(true);
            $prop->setValue(null, []);
            $new['rules'] = $this->syncRules($old);
            if ((string)$mdl->general->enabled == '1') {
                $new['system'] = $this->applySystem();
                $new['interfaces'] = $this->applyInterfaces();
                $new['tunable'] = $this->applyTunable();
            }
            $tunableTouched = $tunableTouched || !empty($new['tunable']);
            $new['hash'] = $this->settingsHash();
            $mdl->applied = json_encode($new);
            $mdl->serializeToConfig(false, true);
            Config::getInstance()->save();
        } catch (ValidationException $e) {
            throw new UserException($e->getMessage(), gettext('Attack protection'));
        }

        $backend = new Backend();
        $status = trim($backend->configdRun('filter reload'));
        if ($tunableTouched) {
            $backend->configdpRun('service restart', ['sysctl']);
        }
        $backend->configdRun('cron restart');
        $siem = '/usr/local/etc/syslog-ng.conf.d/jkufw-siem.conf';
        $before = is_file($siem) ? md5_file($siem) : '';
        $backend->configdRun('template reload OPNsense/JkUfw/Siem');
        clearstatcache();
        if ((is_file($siem) ? md5_file($siem) : '') !== $before) {
            $backend->configdRun('syslog restart');
        }
        /* download the threat feeds now instead of waiting for the next scheduled refresh */
        $backend->configdRun('filter refresh_aliases', true);
        $backend->configdRun('jkufw_ddos tick');
        return ['status' => $status === '' || stripos($status, 'ok') === 0 ? 'ok' : $status];
    }

    /**
     * Put back what the previous apply changed outside the rules: firewall options, interfaces, tunable.
     * A value is only put back while it still is what we set (a later change by hand wins).
     */
    private function restoreSystem($old)
    {
        $cfg = Config::getInstance()->object();
        foreach ($old['system'] ?? [] as $key => [$orig, $ours]) {
            if ((string)($cfg->system->$key ?? '') === (string)$ours) {
                if ($orig === null) {
                    unset($cfg->system->$key);
                } else {
                    $cfg->system->$key = $orig;
                }
            }
        }
        foreach ($old['interfaces'] ?? [] as $ifname => $orig) {
            if (isset($cfg->interfaces->$ifname) && $orig === null) {
                unset($cfg->interfaces->$ifname->blockbogons);
            }
        }
        if (!empty($old['tunable'])) {
            [$orig, $ours] = $old['tunable'];
            $tun = new Tunables();
            foreach ($tun->item->iterateItems() as $uuid => $item) {
                if ((string)$item->tunable == 'net.inet.icmp.icmplim' && (string)$item->value === (string)$ours) {
                    if ($orig === null) {
                        $tun->item->del($uuid);
                    } else {
                        $item->value = $orig;
                    }
                }
            }
            $tun->serializeToConfig(false, true);
        }
    }

    /**
     * our aliases: automatic block list (pf table filled by overload), hand-made deny list, one URL table
     * per threat feed and one for own indicators. Aliases nothing needs any more are removed.
     */
    private function syncAliases()
    {
        $mdl = $this->getModel();
        $enabled = (string)$mdl->general->enabled == '1';
        $want = [];
        if ($enabled) {
            $want[Ddos::TABLE_BLOCK] = ['external', [], null, 'Attack protection: addresses over a limit (filled by pf)'];
            $deny = array_filter(explode(',', (string)$mdl->general->deny));
            if (!empty($deny)) {
                $want[Ddos::TABLE_DENY] = ['network', $deny, null, 'Attack protection: blocked by hand'];
            }
        }
        foreach ($mdl->ioc->feed->iterateItems() as $uuid => $feed) {
            if ((string)$feed->enabled == '1') {
                $name = Ddos::IOC_PREFIX . substr(str_replace('-', '', $uuid), 0, 8);
                $want[$name] = ['urltable', [(string)$feed->url], round((int)(string)$feed->refresh / 24, 4),
                    'Threat feed: ' . (string)$feed->name];
            }
        }
        $custom = array_filter(explode(',', (string)$mdl->ioc->custom));
        if (!empty($custom)) {
            $want[Ddos::IOC_PREFIX . 'custom'] = ['network', $custom, null, 'Threat indicators added by hand'];
        }

        $aliases = new Alias();
        $have = [];
        foreach ($aliases->aliases->alias->iterateItems() as $uuid => $alias) {
            $name = (string)$alias->name;
            if (str_starts_with($name, Ddos::IOC_PREFIX) || in_array($name, [Ddos::TABLE_BLOCK, Ddos::TABLE_DENY], true)) {
                $have[$name] = $uuid;
            }
        }
        foreach ($want as $name => [$type, $content, $freq, $descr]) {
            if (isset($have[$name])) {
                $node = $aliases->getNodeByReference('aliases.alias.' . $have[$name]);
                unset($have[$name]);
            } else {
                $node = $aliases->aliases->alias->Add();
            }
            $node->enabled = '1';
            $node->name = $name;
            $node->type = $type;
            $node->content = implode("\n", $content);
            $node->updatefreq = $freq === null ? '' : (string)$freq;
            $node->description = $descr;
        }
        $this->staleAliases = $have;
        $aliases->serializeToConfig();
        $this->aliasUuid = [];
        foreach ($aliases->aliases->alias->iterateItems() as $uuid => $alias) {
            if (isset($want[(string)$alias->name])) {
                $this->aliasUuid[(string)$alias->name] = $uuid;
            }
        }
    }

    private $staleAliases = [];
    private $aliasUuid = [];

    /**
     * Put back the limits of the previous apply, write our block rules, put the limits on again.
     * Returns what was changed per rule: [uuid => [field => [original, ours]]].
     */
    private function syncRules($old)
    {
        $mdl = $this->getModel();
        $enabled = (string)$mdl->general->enabled == '1';
        $filter = new Filter();

        /* 1. limits of the previous apply */
        foreach ($old['rules'] ?? [] as $uuid => $fields) {
            $rule = $filter->getNodeByReference('rules.rule.' . $uuid);
            if ($rule === null) {
                continue;
            }
            foreach ($fields as $field => [$orig, $ours]) {
                if ((string)$rule->$field === (string)$ours) {
                    $rule->$field = $orig;
                }
            }
        }

        /* 2. our block rules */
        $remove = [];
        foreach ($filter->rules->rule->iterateItems() as $uuid => $rule) {
            $d = (string)$rule->description;
            if (str_starts_with($d, Ddos::RULE_TAG) || str_starts_with($d, Ddos::IOC_TAG)) {
                $remove[] = $uuid;
            }
        }
        foreach ($remove as $uuid) {
            $filter->rules->rule->del($uuid);
        }
        $base = [
            'enabled' => '1', 'action' => 'block', 'quick' => '1', 'ipprotocol' => 'inet46', 'protocol' => 'any',
            'source_net' => 'any', 'source_not' => '0', 'destination_net' => 'any', 'destination_not' => '0',
            'destination_port' => '', 'source_port' => '',
        ];
        $protected = [];
        foreach ($mdl->interfaces->interface->iterateItems() as $node) {
            if ((string)$node->enabled == '1' && isset(Config::getInstance()->object()->interfaces->{(string)$node->interface})) {
                $protected[(string)$node->interface] = $node;
            }
        }
        if ($enabled && !empty($protected)) {
            $sources = array_values(array_filter([Ddos::TABLE_BLOCK, Ddos::TABLE_DENY], fn($a) => isset($this->aliasUuid[$a])));
            $filter->rules->rule->Add()->setNodes(array_merge($base, [
                'sequence' => (string)Ddos::SEQUENCE,
                'interface' => implode(',', array_keys($protected)),
                'direction' => 'in',
                'source_net' => implode(',', $sources),
                'log' => '1',
                'description' => Ddos::RULE_TAG . ' blocked attackers',
            ]));
        }
        $ioc = array_values(array_filter(array_keys($this->aliasUuid), fn($a) => str_starts_with($a, Ddos::IOC_PREFIX)));
        if (!empty($ioc)) {
            $log = (string)$mdl->ioc->log == '1' ? '1' : '0';
            $filter->rules->rule->Add()->setNodes(array_merge($base, [
                'sequence' => (string)(Ddos::SEQUENCE + 1),
                'interface' => '', 'direction' => 'any', 'source_net' => implode(',', $ioc), 'log' => $log,
                'description' => Ddos::IOC_TAG . ' traffic from threat feed addresses',
            ]));
            $filter->rules->rule->Add()->setNodes(array_merge($base, [
                'sequence' => (string)(Ddos::SEQUENCE + 2),
                'interface' => '', 'direction' => 'any', 'destination_net' => implode(',', $ioc), 'log' => $log,
                'description' => Ddos::IOC_TAG . ' traffic to threat feed addresses',
            ]));
        }

        /* 3. limits on the open pass rules of the protected interfaces (only fields left empty by the user) */
        $changes = [];
        if ($enabled && isset($this->aliasUuid[Ddos::TABLE_BLOCK])) {
            foreach ($protected as $ifname => $node) {
                $lim = Ddos::limits($node);
                foreach (self::openRules($filter, $ifname) as $uuid => $rule) {
                    if (isset($changes[$uuid])) {
                        continue;   // rule on several protected interfaces: first one wins
                    }
                    $set = ['max-src-states' => (string)$lim['states']];
                    if (self::isTcp($rule)) {
                        $set['max-src-conn'] = (string)$lim['conns'];
                        if ((string)$rule->{'max-src-conn-rate'} === '' && (string)$rule->{'max-src-conn-rates'} === '') {
                            $set['max-src-conn-rate'] = (string)$lim['rate'];
                            $set['max-src-conn-rates'] = (string)$lim['per'];
                            if ((string)$rule->overload === '') {
                                $set['overload'] = $this->aliasUuid[Ddos::TABLE_BLOCK];
                            }
                        }
                        if ($lim['synproxy'] == '1' && (string)$rule->statetype == 'keep') {
                            $set['statetype'] = 'synproxy';
                        }
                    }
                    foreach ($set as $field => $value) {
                        $cur = (string)$rule->$field;
                        if ($field != 'statetype' && $cur !== '') {
                            continue;
                        }
                        $rule->$field = $value;
                        $changes[$uuid][$field] = [$cur, $value];
                    }
                }
            }
        }
        $filter->serializeToConfig();

        if (!empty($this->staleAliases)) {
            $aliases = new Alias();
            foreach ($this->staleAliases as $uuid) {
                $aliases->aliases->alias->del($uuid);
            }
            $aliases->serializeToConfig(false, true);
        }
        return $changes;
    }

    /**
     * pf options (System > Settings > Firewall): [key => [original, ours]]
     */
    private function applySystem()
    {
        $mdl = $this->getModel();
        $cfg = Config::getInstance()->object();
        $want = ['optimization' => (string)$mdl->general->optimization];
        $cookies = (string)$mdl->general->syncookies;
        if ($cookies != 'off') {
            $want['syncookies'] = $cookies;
            if ($cookies == 'adaptive') {
                $want['syncookies_adaptstart'] = '25';
                $want['syncookies_adaptend'] = '12';
            }
        }
        if ((string)$mdl->general->adaptive == '1' && empty((string)$cfg->system->adaptivestart)) {
            $stats = json_decode((new Backend())->configdRun('jkufw_ddos stats'), true) ?? [];
            $limit = !empty((string)$cfg->system->maximumstates) ? (int)(string)$cfg->system->maximumstates
                : (int)($stats['limit'] ?? 0);
            if ($limit > 0) {
                $want['adaptivestart'] = (string)intdiv($limit * 6, 10);
                $want['adaptiveend'] = (string)intdiv($limit * 12, 10);
            }
        }
        $result = [];
        foreach ($want as $key => $value) {
            $orig = isset($cfg->system->$key) ? (string)$cfg->system->$key : null;
            if ($orig === $value) {
                continue;
            }
            $cfg->system->$key = $value;
            $result[$key] = [$orig, $value];
        }
        return $result;
    }

    /**
     * bogon blocking on the protected interfaces: [interface => original (null = was off)]
     */
    private function applyInterfaces()
    {
        $mdl = $this->getModel();
        $cfg = Config::getInstance()->object();
        $result = [];
        if ((string)$mdl->general->bogons != '1') {
            return $result;
        }
        foreach ($mdl->interfaces->interface->iterateItems() as $node) {
            $ifname = (string)$node->interface;
            if ((string)$node->enabled == '1' && isset($cfg->interfaces->$ifname) && !isset($cfg->interfaces->$ifname->blockbogons)) {
                $cfg->interfaces->$ifname->blockbogons = '1';
                $result[$ifname] = null;
            }
        }
        return $result;
    }

    /**
     * limit of ICMP errors / TCP resets the firewall sends per second: [original, ours] or null
     */
    private function applyTunable()
    {
        $value = (string)$this->getModel()->general->icmplimit;
        $tun = new Tunables();
        $found = null;
        foreach ($tun->item->iterateItems() as $item) {
            if ((string)$item->tunable == 'net.inet.icmp.icmplim') {
                $found = $item;
            }
        }
        if ($found !== null) {
            $orig = (string)$found->value;
            if ($orig === $value) {
                return null;
            }
            $found->value = $value;
        } else {
            $orig = null;
            $found = $tun->item->Add();
            $found->setNodes(['tunable' => 'net.inet.icmp.icmplim', 'value' => $value, 'descr' => 'jk-ufw: attack protection']);
        }
        $tun->serializeToConfig(false, true);
        return [$orig, $value];
    }

    private function addressAction($command)
    {
        if (!$this->request->isPost()) {
            return ['status' => 'failed'];
        }
        $address = trim((string)$this->request->getPost('address'));
        if ($address !== 'ALL' && !Ddos::isNet($address)) {
            return ['status' => 'failed', 'message' => gettext('Not an address or network.')];
        }
        $out = json_decode((new Backend())->configdpRun('jkufw_ddos ' . $command, [$address]), true);
        return is_array($out) ? $out : ['status' => 'failed'];
    }

    public function blockAction()
    {
        return $this->addressAction('block');
    }

    public function unblockAction()
    {
        return $this->addressAction('unblock');
    }

    public function siemtestAction()
    {
        if (!$this->request->isPost()) {
            return ['status' => 'failed'];
        }
        $uuid = (string)$this->request->getPost('uuid');
        foreach ($this->getModel()->siem->target->iterateItems() as $id => $t) {
            if ($id === $uuid) {
                $out = json_decode((new Backend())->configdpRun('jkufw_ddos siemtest', [
                    (string)$t->host, (string)$t->port, (string)$t->transport, (string)$t->format
                ]), true);
                return is_array($out) ? $out : ['status' => 'failed'];
            }
        }
        return ['status' => 'failed', 'message' => gettext('Save the collector first.')];
    }
}
