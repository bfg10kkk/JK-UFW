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
use OPNsense\Base\FieldTypes\JsonKeyValueStoreField;
use OPNsense\Base\UserException;
use OPNsense\Base\ValidationException;
use OPNsense\Core\Backend;
use OPNsense\Core\Config;
use OPNsense\Firewall\Alias;
use OPNsense\Firewall\Filter;
use OPNsense\JkUfw\Sdwan;
use OPNsense\Routing\GatewayGroups;
use OPNsense\Routing\Gateways;

/**
 * jk-ufw SD-WAN API (/api/jkufw/sdwan/*).
 *
 * get/set            general settings (mode, links in priority order, trigger, internal networks)
 * *Policy            traffic routes ("this traffic over that link")
 * link (POST)        per link: name, check address, weight, tariff speed
 * status             links with live health and traffic counters, which links carry traffic now, recent failovers
 * apply (POST)       turn it all into gateways, gateway groups, aliases and floating rules (see Sdwan.php)
 *
 * Every gateway group named JKUFW_SDWAN*, alias named jkufw_sdwan_* and rule tagged [jk-ufw sdwan] is owned
 * by this controller and rewritten on apply. Disabling SD-WAN and applying removes them all again.
 */
class SdwanController extends ApiMutableModelControllerBase
{
    protected static $internalModelClass = '\OPNsense\JkUfw\Sdwan';
    protected static $internalModelName = 'sdwan';

    public function searchPolicyAction()
    {
        return $this->searchBase(
            'policies.policy',
            ['enabled', 'name', 'source', 'app', 'protocol', 'ports', 'destination', 'wan', 'fallback']
        );
    }

    public function getPolicyAction($uuid = null)
    {
        return $this->getBase('policy', 'policies.policy', $uuid);
    }

    public function addPolicyAction()
    {
        return $this->addBase('policy', 'policies.policy');
    }

    public function setPolicyAction($uuid)
    {
        return $this->setBase('policy', 'policies.policy', $uuid);
    }

    public function delPolicyAction($uuid)
    {
        return $this->delBase('policies.policy', $uuid);
    }

    public function togglePolicyAction($uuid, $enabled = null)
    {
        return $this->toggleBase('policies.policy', $uuid, $enabled);
    }

    /**
     * Save the settings of one link: POST {gateway, label, monitor, weight, speed}.
     */
    public function linkAction()
    {
        if (!$this->request->isPost()) {
            return ['result' => 'failed'];
        }
        $data = $this->request->getPost('link');
        if (!is_array($data) || empty($data['gateway'])) {
            return ['result' => 'failed'];
        }
        Config::getInstance()->lock();
        $this->throwReadOnly();
        $mdl = $this->getModel();
        $node = $this->linkNode($data['gateway']) ?? $mdl->links->link->Add();
        $node->setNodes([
            'gateway' => (string)$data['gateway'],
            'label' => (string)($data['label'] ?? ''),
            'monitor' => (string)($data['monitor'] ?? ''),
            'weight' => (string)($data['weight'] ?? '1'),
            'speed' => (string)($data['speed'] ?? ''),
        ]);
        return $this->validateAndSave($node, 'link');
    }

    private function linkNode($gateway)
    {
        foreach ($this->getModel()->links->link->iterateItems() as $node) {
            if ((string)$node->gateway === $gateway) {
                return $node;
            }
        }
        return null;
    }

    /**
     * IPv4 gateways that can serve as internet links: name => gateway info from the routing model.
     */
    private function wanGateways()
    {
        $result = [];
        foreach ((new Gateways())->gatewaysIndexedByName(true, false, true) as $name => $gw) {
            if (($gw['ipprotocol'] ?? '') === 'inet' && empty($gw['is_loopback'])) {
                $result[$name] = $gw;
            }
        }
        return $result;
    }

    private static function num($value)
    {
        return preg_match('/^-?[0-9.]+/', (string)$value, $m) ? (float)$m[0] : null;
    }

    public function statusAction()
    {
        $backend = new Backend();
        $cfg = Config::getInstance()->object();
        $mdl = $this->getModel();
        $gwStatus = json_decode($backend->configdRun('interface gateways status'), true) ?? [];
        $traffic = json_decode($backend->configdRun('interface show traffic'), true) ?? [];
        $members = array_values(array_filter(explode(',', (string)$mdl->general->members)));
        $enabled = !empty((string)$mdl->general->enabled);

        /* which links carry traffic right now: members of the first tier that is up, as pf uses them */
        $carrying = [];
        if ($enabled) {
            $active = (new GatewayGroups())->getActiveGroups($gwStatus);
            foreach ($active[Sdwan::GROUP] ?? [] as $item) {
                $carrying[] = $item['name'];
            }
        }

        $links = [];
        $wanIfs = [];
        foreach ($this->wanGateways() as $name => $gw) {
            $st = $gwStatus[$name] ?? null;
            $ifname = $gw['interface'] ?? '';
            $wanIfs[$ifname] = true;
            $own = $this->linkNode($name);
            $tr = $traffic['interfaces'][$ifname] ?? [];
            $links[] = [
                'name' => $name,
                'label' => $own !== null ? (string)$own->label : '',
                'descr' => (string)($gw['descr'] ?? ''),
                'interface' => $ifname,
                'interface_descr' => (string)($cfg->interfaces->$ifname->descr ?? '') ?: strtoupper($ifname),
                'device' => $gw['if'] ?? '',
                'address' => $gw['gateway'] ?? '',
                'dynamic' => !empty($gw['dynamic']),
                'disabled' => !empty($gw['disabled']),
                'monitoring' => empty($gw['monitor_disable']),
                'monitor' => $own !== null && (string)$own->monitor !== '' ? (string)$own->monitor : ($gw['monitor'] ?? ''),
                'weight' => (int)($own !== null ? (string)$own->weight : ($gw['weight'] ?? 1)),
                'speed' => $own !== null ? (int)(string)$own->speed : 0,
                'status' => $st['status'] ?? 'pending',
                'delay' => self::num($st['delay'] ?? null),
                'stddev' => self::num($st['stddev'] ?? null),
                'loss' => self::num($st['loss'] ?? null),
                'member' => in_array($name, $members, true),
                'order' => array_search($name, $members, true),
                'carrying' => in_array($name, $carrying, true),
                'inbytes' => isset($tr['bytes received']) ? (float)$tr['bytes received'] : null,
                'outbytes' => isset($tr['bytes transmitted']) ? (float)$tr['bytes transmitted'] : null,
            ];
        }

        /* internal networks: enabled interfaces without a gateway of their own */
        $lans = [];
        foreach ($cfg->interfaces->children() as $ifname => $if) {
            if (isset($wanIfs[$ifname]) || empty((string)$if->enable) || $ifname == 'lo0' || (string)$if->type == 'group') {
                continue;
            }
            $net = '';
            if (filter_var((string)$if->ipaddr, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4) && (string)$if->subnet !== '') {
                $net = (string)$if->ipaddr . '/' . (string)$if->subnet;
            }
            $lans[] = ['name' => $ifname, 'descr' => (string)$if->descr ?: strtoupper($ifname), 'net' => $net];
        }

        $rules = 0;
        foreach ((new Filter())->rules->rule->iterateItems() as $rule) {
            if (str_starts_with((string)$rule->description, Sdwan::RULE_TAG)) {
                $rules++;
            }
        }

        return [
            'enabled' => $enabled,
            'applied_rules' => $rules,
            'mode' => (string)$mdl->general->mode,
            'members' => $members,
            'trigger' => (string)$mdl->general->trigger,
            'sticky' => !empty((string)$mdl->general->sticky),
            'killstates' => !empty((string)$mdl->general->killstates),
            'lans_selected' => array_values(array_filter(explode(',', (string)$mdl->general->lans))),
            'switch_default' => !empty((string)$cfg->system->gw_switch_default),
            'time' => $traffic['time'] ?? microtime(true),
            'links' => $links,
            'lans' => $lans,
            'events' => $this->events(array_column($links, 'name')),
        ];
    }

    /**
     * Last link state changes from the gateway log, newest first.
     */
    private function events($names)
    {
        $file = '/var/log/gateways/latest.log';
        if (!is_readable($file)) {
            return [];
        }
        $size = filesize($file);
        $fh = fopen($file, 'r');
        fseek($fh, max(0, $size - 65536));
        $lines = explode("\n", stream_get_contents($fh));
        fclose($fh);
        $result = [];
        $re = '/(ALERT|MONITOR): (\S+) \(Addr: (\S+) Alarm: (\S+) -> (\S+) RTT: ([^ ]*) ?\S* RTTd: ([^ ]*) ?\S* Loss: ([^)]*)\)/';
        foreach (array_reverse($lines) as $line) {
            if (!preg_match($re, $line, $m) || !in_array($m[2], $names, true)) {
                continue;
            }
            preg_match('/\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d[^ ]*/', $line, $ts);
            $result[] = [
                'time' => $ts[0] ?? null,
                'alert' => $m[1] == 'ALERT',
                'gateway' => $m[2],
                'from' => $m[4],
                'to' => $m[5],
                'delay' => self::num($m[6]),
                'loss' => self::num($m[8]),
            ];
            if (count($result) >= 30) {
                break;
            }
        }
        return $result;
    }

    /**
     * Write gateways, groups, aliases and rules, then reload routing and the firewall.
     */
    public function applyAction()
    {
        if (!$this->request->isPost()) {
            return ['status' => 'failed'];
        }
        Config::getInstance()->lock();
        $this->throwReadOnly();
        try {
            $this->syncObjects();
            Config::getInstance()->save();
            $this->resetOptionCaches();
            $this->syncRules();
            Config::getInstance()->save();
        } catch (ValidationException $e) {
            throw new UserException($e->getMessage(), 'SD-WAN');
        }
        $backend = new Backend();
        /* restarts dpinger with the new check addresses and sets the default route */
        $backend->configdRun('interface routes configure');
        $status = trim($backend->configdRun('filter reload'));
        return ['status' => $status === '' ? 'OK' : $status];
    }

    /**
     * Gateways (monitoring, weight, priority), gateway groups, aliases. Saved before the rules, because rule
     * validation looks these names up.
     */
    private function syncObjects()
    {
        $mdl = $this->getModel();
        $cfg = Config::getInstance()->object();
        $enabled = !empty((string)$mdl->general->enabled);
        $all = $this->wanGateways();
        $members = array_values(array_filter(
            explode(',', (string)$mdl->general->members),
            fn($n) => isset($all[$n]) && empty($all[$n]['disabled'])
        ));
        if ($enabled && count($members) < 1) {
            throw new UserException(gettext('Choose at least one internet link.'), 'SD-WAN');
        }
        $balance = (string)$mdl->general->mode == 'balance';
        $trigger = (string)$mdl->general->trigger;

        /* 1. gateways: monitoring on, own check address, weight, priority in member order */
        if ($enabled) {
            $gwMdl = new Gateways();
            $used = [];
            foreach ($members as $name) {
                $own = $this->linkNode($name);
                if ($own !== null && (string)$own->monitor !== '') {
                    $used[(string)$own->monitor] = true;
                }
            }
            foreach ($members as $idx => $name) {
                $gw = $all[$name];
                $own = $this->linkNode($name);
                $monitor = $own !== null ? (string)$own->monitor : '';
                if ($monitor === '') {
                    $monitor = !empty($gw['monitor']) && empty($used[$gw['monitor']]) && $gw['monitor'] != ($gw['gateway'] ?? '')
                        ? $gw['monitor'] : '';
                }
                if ($monitor === '') {
                    foreach (Sdwan::MONITORS as $candidate) {
                        if (empty($used[$candidate])) {
                            $monitor = $candidate;
                            break;
                        }
                    }
                }
                $used[$monitor] = true;
                $node = !empty($gw['uuid']) ? $gwMdl->getNodeByReference('gateway_item.' . $gw['uuid']) : null;
                if ($node === null) {
                    /* automatic (e.g. DHCP) gateway without own settings yet: store it, like the gateway editor does */
                    $node = $gwMdl->gateway_item->Add();
                    $copy = $gw;
                    unset($copy['uuid']);
                    if (!empty($copy['dynamic'])) {
                        $copy['gateway'] = '';
                    }
                    $node->setNodes(array_filter($copy, fn($v) => !is_array($v)));
                }
                $node->monitor_disable = '0';
                $node->monitor = $monitor;
                $node->weight = $own !== null ? (string)$own->weight : '1';
                $node->priority = (string)($balance ? 10 : 10 + $idx);
                $node->monitor_killstates = !empty((string)$mdl->general->killstates) ? '1' : '0';
                if ($own !== null && (string)$own->monitor !== $monitor) {
                    $own->monitor = $monitor;
                }
            }
            $gwMdl->serializeToConfig();
            $this->getModel()->serializeToConfig(false, true);
            /* firewall's own traffic follows the healthy link with the lowest priority */
            $cfg->system->gw_switch_default = '1';
        }

        /* 2. gateway groups */
        $groups = new GatewayGroups();
        $remove = [];
        foreach ($groups->gateway_group->iterateItems() as $uuid => $grp) {
            if (str_starts_with((string)$grp->name, Sdwan::GROUP)) {
                $remove[(string)$grp->name] = $uuid;
            }
        }
        $want = [];
        if ($enabled) {
            $want[Sdwan::GROUP] = [$balance ? [$members] : array_map(fn($m) => [$m], $members), 'SD-WAN: ' . ($balance ? 'load balancing' : 'failover')];
            foreach ($this->activePolicies($all) as $pol) {
                if ($pol['group'] !== null) {
                    $others = array_values(array_diff($members, [$pol['wan']]));
                    $tiers = [[$pol['wan']]];
                    if (!empty($others)) {
                        if ($balance) {
                            $tiers[] = $others;
                        } else {
                            foreach ($others as $o) {
                                $tiers[] = [$o];
                            }
                        }
                    }
                    $want[$pol['group']] = [$tiers, 'SD-WAN: ' . $pol['name']];
                }
            }
        }
        foreach ($want as $name => [$tiers, $descr]) {
            if (isset($remove[$name])) {
                $node = $groups->getNodeByReference('gateway_group.' . $remove[$name]);
                unset($remove[$name]);
            } else {
                $node = $groups->gateway_group->Add();
                $node->name = $name;
            }
            $tiers = array_slice($tiers, 0, 5);
            foreach (['item', 'item2', 'item3', 'item4', 'item5'] as $i => $prop) {
                $node->$prop = isset($tiers[$i]) ? implode(',', $tiers[$i]) : '';
            }
            $node->trigger = $trigger;
            $node->poolopts = $balance && !empty((string)$mdl->general->sticky) ? 'round-robin sticky-address' : '';
            $node->descr = $descr;
        }
        /* old groups go after the rules stop using them (syncRules) */
        $this->staleGroups = $remove;
        $groups->serializeToConfig(false, true);

        /* 3. aliases */
        $aliases = new Alias();
        $have = [];
        foreach ($aliases->aliases->alias->iterateItems() as $uuid => $alias) {
            if (str_starts_with((string)$alias->name, Sdwan::PREFIX)) {
                $have[(string)$alias->name] = $uuid;
            }
        }
        $wantAliases = [];
        if ($enabled) {
            $wantAliases[Sdwan::PREFIX . 'local'] = ['network', Sdwan::LOCAL_NETS, 'SD-WAN: local and private networks'];
            foreach ($this->activePolicies($all) as $pol) {
                foreach ($pol['aliases'] as $name => $alias) {
                    $wantAliases[$name] = $alias;
                }
            }
        }
        foreach ($wantAliases as $name => [$type, $content, $descr]) {
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
            $node->description = $descr;
        }
        $this->staleAliases = $have;
        $aliases->serializeToConfig();
    }

    private $staleGroups = [];
    private $staleAliases = [];

    /**
     * Enabled policies whose link is usable, with the names of the objects they need.
     */
    private function activePolicies($all)
    {
        $result = [];
        $mdl = $this->getModel();
        foreach ($mdl->policies->policy->iterateItems() as $uuid => $pol) {
            $wan = (string)$pol->wan;
            if (empty((string)$pol->enabled) || !isset($all[$wan])) {
                continue;
            }
            $id = substr(str_replace('-', '', $uuid), 0, 8);
            [$proto, $ports] = Sdwan::policyPorts($pol);
            $sources = array_values(array_filter(explode(',', (string)$pol->source)));
            $dests = array_values(array_filter(explode(',', (string)$pol->destination)));
            $item = [
                'id' => $id,
                'name' => (string)$pol->name,
                'wan' => $wan,
                'group' => !empty((string)$pol->fallback) ? Sdwan::GROUP . '_' . strtoupper($id) : null,
                'protocol' => $proto,
                'source' => null,
                'destination' => null,
                'port' => null,
                'aliases' => [],
            ];
            $net = fn($a) => str_contains($a, '/') ? $a : $a . '/32';
            if (!empty($sources)) {
                $item['source'] = Sdwan::PREFIX . 's_' . $id;
                $item['aliases'][$item['source']] = ['network', array_map($net, $sources), 'SD-WAN: ' . $item['name'] . ' (devices)'];
            }
            if (!empty($dests)) {
                $item['destination'] = Sdwan::PREFIX . 'd_' . $id;
                $item['aliases'][$item['destination']] = ['network', array_map($net, $dests), 'SD-WAN: ' . $item['name'] . ' (addresses)'];
            }
            if (!empty($ports)) {
                $item['port'] = Sdwan::PREFIX . 'p_' . $id;
                $item['aliases'][$item['port']] = ['port', $ports, 'SD-WAN: ' . $item['name'] . ' (ports)'];
            }
            $result[] = $item;
        }
        return $result;
    }

    /**
     * Option lists of model fields are cached per request (aliases, gateway names; configd even caches its
     * gateway list for 20 seconds). Make the rule validation see the objects just written.
     */
    private function resetOptionCaches()
    {
        $prop = new \ReflectionProperty(BaseListField::class, 'internalStaticOptList');
        $prop->setAccessible(true);
        $prop->setValue(null, []);

        $names = [];
        foreach ($this->wanGateways() as $name => $gw) {
            $names[$name] = $name;
        }
        foreach ((new Gateways())->gatewaysIndexedByName(true, true, true) as $name => $gw) {
            $names[$name] = $name;
        }
        foreach ((new GatewayGroups())->getGroupNames() as $name) {
            $names[$name] = $name;
        }
        $prop = new \ReflectionProperty(JsonKeyValueStoreField::class, 'internalStaticContent');
        $prop->setAccessible(true);
        $content = $prop->getValue();
        foreach (['interface gateways list -g', 'interface gateways list'] as $key) {
            if (isset($content[$key]) || $key == 'interface gateways list -g') {
                $content[$key] = array_merge($content[$key] ?? [], $names);
            }
        }
        $prop->setValue(null, $content);
    }

    private function syncRules()
    {
        $mdl = $this->getModel();
        $enabled = !empty((string)$mdl->general->enabled);
        $tag = Sdwan::RULE_TAG;
        $all = $this->wanGateways();

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

        if ($enabled) {
            $cfg = Config::getInstance()->object();
            $lans = array_values(array_filter(
                explode(',', (string)$mdl->general->lans),
                fn($i) => isset($cfg->interfaces->$i)
            ));
            if (empty($lans)) {
                throw new UserException(gettext('Choose at least one internal network.'), 'SD-WAN');
            }
            /*
             * Floating (no interface), inbound, quick: matched before the interface rules, so the route is taken
             * for every internal network at once. The source limits them to the internal networks and the
             * destination skips local and private addresses, so traffic between networks and to the firewall
             * itself is left to the normal rules.
             */
            $base = [
                'enabled' => '1', 'action' => 'pass', 'quick' => '1', 'interface' => '', 'direction' => 'in',
                'ipprotocol' => 'inet', 'protocol' => 'any', 'source_net' => implode(',', $lans), 'source_not' => '0',
                'destination_net' => Sdwan::PREFIX . 'local', 'destination_not' => '1', 'destination_port' => '',
                'log' => '0',
            ];
            $seq = Sdwan::SEQUENCE;
            foreach ($this->activePolicies($all) as $pol) {
                $rule = array_merge($base, [
                    'sequence' => (string)$seq++,
                    'protocol' => $pol['protocol'],
                    'gateway' => $pol['group'] ?? $pol['wan'],
                    'description' => "{$tag} {$pol['name']}",
                ]);
                if ($pol['source'] !== null) {
                    $rule['source_net'] = $pol['source'];
                }
                if ($pol['destination'] !== null) {
                    $rule['destination_net'] = $pol['destination'];
                    $rule['destination_not'] = '0';
                }
                if ($pol['port'] !== null) {
                    $rule['destination_port'] = $pol['port'];
                }
                $filter->rules->rule->Add()->setNodes($rule);
            }
            $filter->rules->rule->Add()->setNodes(array_merge($base, [
                'sequence' => (string)(Sdwan::SEQUENCE + 999),
                'gateway' => Sdwan::GROUP,
                'description' => "{$tag} internet over all links",
            ]));
        }
        $filter->serializeToConfig();

        /* objects no rule uses any more */
        if (!empty($this->staleGroups)) {
            $groups = new GatewayGroups();
            foreach ($this->staleGroups as $uuid) {
                $groups->gateway_group->del($uuid);
            }
            $groups->serializeToConfig(false, true);
        }
        if (!empty($this->staleAliases)) {
            $aliases = new Alias();
            foreach ($this->staleAliases as $uuid) {
                $aliases->aliases->alias->del($uuid);
            }
            $aliases->serializeToConfig();
        }
    }
}
