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
use OPNsense\JkUfw\Parental;

/**
 * jk-ufw parental control API (/api/jkufw/parental/*).
 *
 * Devices are stored in OPNsense/JkUfw/parental. apply() regenerates, for every enabled device:
 *   - alias      jkufw_<id>   (host or MAC alias with the device addresses)
 *   - schedule   jkufw_<id>   (legacy firewall schedule: the hours internet is ALLOWED)
 *   - rule       pass  from jkufw_<id>, scheduled   (floating, quick)
 *   - rule       reject from jkufw_<id>              (floating, quick, right after it)
 * Outside the allowed hours the pass rule is unloaded and, as with any schedule, its states are killed,
 * so open connections drop too. A paused device gets only the reject rule.
 * Everything carrying the jkufw_ prefix or the [jk-ufw] rule tag is owned by this controller and rewritten on apply.
 */
class ParentalController extends ApiMutableModelControllerBase
{
    protected static $internalModelClass = '\OPNsense\JkUfw\Parental';
    protected static $internalModelName = 'parental';

    public function searchDeviceAction()
    {
        return $this->searchBase(
            'devices.device',
            ['enabled', 'name', 'addresses', 'paused', 'days', 'block_from', 'block_to']
        );
    }

    public function getDeviceAction($uuid = null)
    {
        return $this->getBase('device', 'devices.device', $uuid);
    }

    public function addDeviceAction()
    {
        return $this->addBase('device', 'devices.device');
    }

    public function setDeviceAction($uuid)
    {
        return $this->setBase('device', 'devices.device', $uuid);
    }

    public function delDeviceAction($uuid)
    {
        return $this->delBase('devices.device', $uuid);
    }

    public function toggleDeviceAction($uuid, $enabled = null)
    {
        return $this->toggleBase('devices.device', $uuid, $enabled);
    }

    /**
     * Pause (1) or resume (0) internet for one device and apply at once; used by the page and the dashboard widget.
     */
    public function pauseAction($uuid, $paused = 1)
    {
        if (!$this->request->isPost()) {
            return ['status' => 'failed'];
        }
        Config::getInstance()->lock();
        $this->throwReadOnly();
        $node = $this->getModel()->getNodeByReference('devices.device.' . $uuid);
        if ($node == null) {
            return ['status' => 'failed', 'message' => 'not found'];
        }
        $node->paused = empty($paused) ? '0' : '1';
        $this->save();
        return $this->applyAction();
    }

    /**
     * Current state of every device: allowed / blocked by schedule / paused / off, and when that changes next.
     */
    public function statusAction()
    {
        $result = ['now' => date('c'), 'weekday' => (int)date('N'), 'devices' => []];
        $nowMin = (int)date('G') * 60 + (int)date('i');
        $today = (int)date('N');
        foreach ($this->getModel()->devices->device->iterateItems() as $uuid => $dev) {
            $item = ['uuid' => $uuid, 'name' => (string)$dev->name, 'state' => 'allowed', 'until' => null];
            $days = array_filter(explode(',', (string)$dev->days));
            if (empty((string)$dev->enabled)) {
                $item['state'] = 'off';
            } elseif (!empty((string)$dev->paused)) {
                $item['state'] = 'paused';
            } elseif (!empty($days)) {
                /* one week of minutes, starting now: find the current state and the next change */
                $ranges = Parental::allowedRanges($days, (string)$dev->block_from, (string)$dev->block_to);
                $isAllowed = function ($offset) use ($ranges, $today, $nowMin) {
                    $abs = $nowMin + $offset;
                    return Parental::allowedAt($ranges, ($today - 1 + intdiv($abs, 1440)) % 7 + 1, $abs % 1440);
                };
                $cur = $isAllowed(0);
                $item['state'] = $cur ? 'allowed' : 'blocked';
                for ($off = 1; $off <= 7 * 1440; $off++) {
                    if ($isAllowed($off) !== $cur) {
                        $item['until'] = date('c', time() - (int)date('s') + $off * 60);
                        break;
                    }
                }
            }
            $result['devices'][] = $item;
        }
        return $result;
    }

    /**
     * Turn the stored devices into aliases, schedules and filter rules, then reload the firewall.
     */
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
            throw new UserException($e->getMessage(), gettext('Parental control'));
        }
        Config::getInstance()->save();
        $backend = new Backend();
        $status = trim($backend->configdRun('filter reload'));
        /* the "reload filter for configured schedules" cron job only exists while some rule has a schedule */
        $backend->configdRun('cron restart');
        $this->killBlockedStates($backend);
        return ['status' => $status === '' ? 'OK' : $status];
    }

    /**
     * Drop open connections of devices that are blocked right now. Later schedule changes do this by themselves
     * (states of an expired scheduled rule are killed), but connections opened before the device was added here
     * belong to other rules and would otherwise survive a pause.
     */
    private function killBlockedStates($backend)
    {
        $weekday = (int)date('N');
        $minute = (int)date('G') * 60 + (int)date('i');
        foreach ($this->activeDevices() as $dev) {
            if (!$dev['paused'] && Parental::allowedAt($dev['ranges'], $weekday, $minute)) {
                continue;
            }
            $ips = $dev['addresses'];
            if ($dev['mac']) {
                /* MAC aliases are resolved to addresses by the alias updater; use what the table holds now */
                $table = json_decode($backend->configdpRun('filter list table', [$dev['id']]), true);
                $ips = array_column($table['items'] ?? [], 'ip');
            }
            foreach ($ips as $ip) {
                $backend->configdpRun('filter kill states', [$ip, '']);
            }
        }
    }

    /**
     * Enabled devices that have something to enforce (a pause or at least one blocked day).
     */
    private function activeDevices()
    {
        $result = [];
        foreach ($this->getModel()->devices->device->iterateItems() as $uuid => $dev) {
            $days = array_filter(explode(',', (string)$dev->days));
            $paused = !empty((string)$dev->paused);
            if (empty((string)$dev->enabled) || (!$paused && empty($days))) {
                continue;
            }
            $addresses = array_values(array_filter(explode(',', (string)$dev->addresses)));
            $from = (string)$dev->block_from;
            $to = (string)$dev->block_to;
            $ranges = Parental::allowedRanges($paused ? [] : $days, $from, $to);
            $timeranges = $paused ? [] : Parental::scheduleTimeranges($days, $from, $to);
            $result[] = [
                'id' => Parental::PREFIX . substr(str_replace('-', '', $uuid), 0, 12),
                'name' => (string)$dev->name,
                'addresses' => $addresses,
                'mac' => !empty($addresses) && Parental::isMac($addresses[0]),
                /* a device blocked around the clock gets no pass rule, same as a paused one */
                'paused' => $paused || empty($timeranges),
                'ranges' => $ranges,
                'timeranges' => $timeranges,
            ];
        }
        return $result;
    }

    private function sync()
    {
        $prefix = Parental::PREFIX;
        $tag = Parental::RULE_TAG;
        $mdl = $this->getModel();
        $cfg = Config::getInstance()->object();

        $devices = $this->activeDevices();

        /* 1. legacy schedules (no MVC model exists for them), written first so the rule validation can see them */
        if (!isset($cfg->schedules)) {
            $cfg->addChild('schedules');
        }
        $stale = [];
        foreach ($cfg->schedules->children() as $node) {
            if (str_starts_with((string)$node->name, $prefix)) {
                $stale[] = dom_import_simplexml($node);
            }
        }
        foreach ($stale as $dom) {
            $dom->parentNode->removeChild($dom);
        }
        foreach ($devices as $dev) {
            if ($dev['paused']) {
                continue;
            }
            $sched = $cfg->schedules->addChild('schedule');
            $sched->name = $dev['id'];
            $sched->descr = 'jk-ufw: ' . $dev['name'];
            foreach ($dev['timeranges'] as $range) {
                $tr = $sched->addChild('timerange');
                foreach ($range as $key => $value) {
                    $tr->$key = $value;
                }
            }
        }
        /* ScheduleField caches the schedule names per request; make sure it reads the ones just written */
        $cache = new \ReflectionProperty(\OPNsense\Firewall\FieldTypes\ScheduleField::class, 'schedules');
        $cache->setAccessible(true);
        $cache->setValue(null, []);

        /* 2. aliases: add or update ours, drop the stale ones after the rules no longer use them */
        $aliases = new Alias();
        $byName = [];
        foreach ($aliases->aliases->alias->iterateItems() as $uuid => $alias) {
            if (str_starts_with((string)$alias->name, $prefix)) {
                $byName[(string)$alias->name] = $uuid;
            }
        }
        foreach ($devices as $dev) {
            if (isset($byName[$dev['id']])) {
                $node = $aliases->getNodeByReference('aliases.alias.' . $byName[$dev['id']]);
                unset($byName[$dev['id']]);
            } else {
                $node = $aliases->aliases->alias->Add();
            }
            $node->enabled = '1';
            $node->name = $dev['id'];
            $node->type = $dev['mac'] ? 'mac' : 'host';
            $node->content = implode("\n", $dev['addresses']);
            $node->description = 'jk-ufw: ' . $dev['name'];
        }
        $staleAliases = $byName;
        $aliases->serializeToConfig();

        /* 3. floating rules, first in the floating section so user rules cannot let a blocked device through */
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
            'ipprotocol' => 'inet46', 'protocol' => 'any', 'source_net' => 'any', 'destination_net' => 'any',
            'destination_not' => '0', 'destination_port' => '', 'sched' => '', 'log' => '0',
        ];
        $seq = 1;
        if (!empty((string)$mdl->general->block_foreign_dns)) {
            foreach (['53' => 'DNS', '853' => 'DNS over TLS'] as $port => $what) {
                $filter->rules->rule->Add()->setNodes(array_merge($base, [
                    'sequence' => (string)$seq++, 'protocol' => 'TCP/UDP', 'destination_net' => '(self)',
                    'destination_not' => '1', 'destination_port' => $port,
                    'description' => "{$tag} {$what} only through this firewall",
                ]));
            }
        }
        $seq = 10;
        foreach ($devices as $dev) {
            if (!$dev['paused']) {
                $filter->rules->rule->Add()->setNodes(array_merge($base, [
                    'sequence' => (string)$seq++, 'action' => 'pass', 'source_net' => $dev['id'], 'sched' => $dev['id'],
                    'description' => "{$tag} {$dev['name']}: internet allowed",
                ]));
            }
            $filter->rules->rule->Add()->setNodes(array_merge($base, [
                'sequence' => (string)$seq++, 'source_net' => $dev['id'],
                'description' => "{$tag} {$dev['name']}: " . ($dev['paused'] ? 'paused' : 'outside allowed hours'),
            ]));
        }
        $filter->serializeToConfig();

        /* 4. stale aliases, now unreferenced */
        if (!empty($staleAliases)) {
            foreach ($staleAliases as $uuid) {
                $aliases->aliases->alias->del($uuid);
            }
            $aliases->serializeToConfig();
        }
    }
}
