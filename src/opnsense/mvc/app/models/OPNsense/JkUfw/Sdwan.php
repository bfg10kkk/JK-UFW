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

namespace OPNsense\JkUfw;

use OPNsense\Base\BaseModel;
use OPNsense\Base\Messages\Message;

/**
 * jk-ufw SD-WAN: two or more internet links behaving like one.
 *
 * The model only stores what the user picked. Api\SdwanController::applyAction() turns it into stock objects,
 * so nothing new runs in the packet path:
 *   - gateway monitoring (dpinger) on every link, with its own check address, weight and priority
 *   - gateway group JKUFW_SDWAN: one tier per link (failover) or all links in one tier (load balancing)
 *   - gateway group JKUFW_SDWAN_<id> per policy that may fall back to the other links
 *   - aliases jkufw_sdwan_* (private networks, policy sources, destinations and ports)
 *   - floating "pass" rules with a gateway, tagged [jk-ufw sdwan], first the policies, then the default route
 *   - "Allow default gateway switching", so the firewall's own traffic (DNS, updates) fails over too
 */
class Sdwan extends BaseModel
{
    const GROUP = 'JKUFW_SDWAN';
    const PREFIX = 'jkufw_sdwan_';
    const RULE_TAG = '[jk-ufw sdwan]';
    /* floating rules are sorted by sequence: ours go after the parental control and guest rules */
    const SEQUENCE = 50000;
    /* addresses that stay local (never policy-routed) */
    const LOCAL_NETS = ['10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16', '100.64.0.0/10', '169.254.0.0/16', '224.0.0.0/4'];
    /* well-known check addresses, one per link (dpinger adds a host route to each, so they must differ) */
    const MONITORS = ['1.1.1.1', '8.8.8.8', '9.9.9.9', '208.67.222.222', '1.0.0.1', '8.8.4.4'];

    /* ports per application preset; ranges as pf aliases want them (from:to) */
    const APPS = [
        'web' => ['TCP/UDP', ['80', '443']],
        'calls' => ['TCP/UDP', ['3478:3481', '5060:5061', '8801:8810', '19302:19309', '10000:20000']],
        'gaming' => ['TCP/UDP', ['3074:3075', '3478:3480', '3659', '9295:9304', '27015:27050']],
        'mail' => ['TCP', ['25', '110', '143', '465', '587', '993', '995']],
        'remote' => ['TCP/UDP', ['22', '3389', '5900', '5938']],
        'vpn' => ['TCP/UDP', ['500', '1194', '1701', '4500', '51820']],
    ];

    /**
     * protocol and port list of a policy, [protocol, ports[]]; ports empty = any
     */
    public static function policyPorts($policy)
    {
        $app = (string)$policy->app;
        if (isset(self::APPS[$app])) {
            return self::APPS[$app];
        }
        if ($app == 'custom') {
            $ports = array_map(fn($p) => str_replace('-', ':', $p), array_filter(explode(',', (string)$policy->ports)));
            return [(string)$policy->protocol, array_values($ports)];
        }
        return ['any', []];
    }

    public function performValidation($validateFullModel = false)
    {
        $messages = parent::performValidation($validateFullModel);

        $members = array_filter(explode(',', (string)$this->general->members));
        if (count($members) != count(array_unique($members))) {
            $messages->appendMessage(new Message(gettext('A link is listed twice.'), 'general.members'));
        }

        $monitors = [];
        foreach ($this->links->link->iterateItems() as $node) {
            $mon = (string)$node->monitor;
            if ($mon === '') {
                continue;
            }
            if (isset($monitors[$mon])) {
                $messages->appendMessage(new Message(
                    gettext('Every link needs its own check address.'),
                    $node->monitor->__reference
                ));
            }
            $monitors[$mon] = true;
        }

        foreach ($this->policies->policy->iterateItems() as $node) {
            if (!$validateFullModel && !$node->isFieldChanged()) {
                continue;
            }
            if ((string)$node->app == 'custom' && trim((string)$node->ports) === '') {
                $messages->appendMessage(new Message(gettext('Enter at least one port.'), $node->ports->__reference));
            }
            foreach (array_filter(explode(',', (string)$node->ports)) as $range) {
                foreach (preg_split('/[:\-]/', $range) as $port) {
                    if ((int)$port < 1 || (int)$port > 65535) {
                        $messages->appendMessage(new Message(gettext('Ports are 1 to 65535.'), $node->ports->__reference));
                        break 2;
                    }
                }
            }
        }

        return $messages;
    }
}
