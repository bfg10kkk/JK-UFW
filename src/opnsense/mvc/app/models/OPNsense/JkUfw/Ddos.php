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
 * jk-ufw attack protection: DDoS limits on internet facing pass rules, threat intelligence block lists,
 * log export to a SIEM. The API (Api/DdosController) turns these settings into ordinary firewall objects.
 */
class Ddos extends BaseModel
{
    /* rules owned by this feature start with these tags; they are rewritten on every apply */
    const RULE_TAG = '[jk-ufw ddos]';
    const IOC_TAG = '[jk-ufw ioc]';
    /* aliases owned by this feature */
    const TABLE_BLOCK = 'jkufw_ddos_block';   // filled by pf when an address crosses a limit (overload)
    const TABLE_DENY = 'jkufw_ddos_deny';     // addresses blocked by hand
    const IOC_PREFIX = 'jkufw_ioc_';          // one URL table per feed, plus jkufw_ioc_custom
    /* floating rules sort by sequence: ours come first, before parental control (1000+) and SD-WAN (50000+) */
    const SEQUENCE = 10;

    /* per interface limits by level: states, conns, rate per "per" seconds, synproxy */
    const LEVELS = [
        'light' => ['states' => 3000, 'conns' => 600, 'rate' => 300, 'per' => 10, 'synproxy' => '0'],
        'standard' => ['states' => 1000, 'conns' => 200, 'rate' => 100, 'per' => 10, 'synproxy' => '0'],
        'strict' => ['states' => 300, 'conns' => 60, 'rate' => 30, 'per' => 10, 'synproxy' => '1'],
    ];

    /* firewall wide settings by preset */
    const PRESETS = [
        'light' => ['syncookies' => 'adaptive', 'adaptive' => '1', 'optimization' => 'normal', 'icmplimit' => '1000'],
        'standard' => ['syncookies' => 'adaptive', 'adaptive' => '1', 'optimization' => 'normal', 'icmplimit' => '500'],
        'strict' => ['syncookies' => 'always', 'adaptive' => '1', 'optimization' => 'aggressive', 'icmplimit' => '200'],
    ];

    /* free threat intelligence feeds offered on the page (plain lists of addresses / networks) */
    const FEEDS = [
        'firehol1' => ['FireHOL Level 1', 'https://iplists.firehol.org/files/firehol_level1.netset', 12],
        'feodo' => ['abuse.ch Feodo Tracker (botnet C2)', 'https://feodotracker.abuse.ch/downloads/ipblocklist.txt', 6],
        'et' => ['Emerging Threats: compromised hosts', 'https://rules.emergingthreats.net/blockrules/compromised-ips.txt', 12],
        'cins' => ['CINS Army', 'https://cinsscore.com/list/ci-badguys.txt', 12],
        'blocklistde' => ['blocklist.de: attackers', 'https://lists.blocklist.de/lists/all.txt', 12],
    ];

    /**
     * limits of one interface entry: [states, conns, rate, per, synproxy]
     */
    public static function limits($node)
    {
        $level = (string)$node->level;
        if (isset(self::LEVELS[$level])) {
            return self::LEVELS[$level];
        }
        $std = self::LEVELS['standard'];
        $get = fn($f) => (string)$node->$f !== '' ? (int)(string)$node->$f : $std[$f];
        return [
            'states' => $get('states'),
            'conns' => $get('conns'),
            'rate' => $get('rate'),
            'per' => $get('per'),
            'synproxy' => (string)$node->synproxy,
        ];
    }

    /**
     * "a.b.c.d" or "a.b.c.d/nn" (IPv4 or IPv6)
     */
    public static function isNet($value)
    {
        $parts = explode('/', $value, 2);
        $v4 = filter_var($parts[0], FILTER_VALIDATE_IP, FILTER_FLAG_IPV4) !== false;
        $v6 = !$v4 && filter_var($parts[0], FILTER_VALIDATE_IP, FILTER_FLAG_IPV6) !== false;
        if (!$v4 && !$v6) {
            return false;
        }
        if (count($parts) == 2) {
            return ctype_digit($parts[1]) && (int)$parts[1] <= ($v4 ? 32 : 128);
        }
        return true;
    }

    public function performValidation($validateFullModel = false)
    {
        $messages = parent::performValidation($validateFullModel);

        foreach (
            [[$this->general->allow, 'general.allow'], [$this->general->deny, 'general.deny'],
            [$this->ioc->custom, 'ioc.custom']] as [$field, $ref]
        ) {
            foreach (array_filter(explode(',', (string)$field)) as $item) {
                if (!self::isNet($item)) {
                    $messages->appendMessage(new Message(sprintf(gettext('Not an address or network: %s'), $item), $ref));
                    break;
                }
            }
        }

        $seen = [];
        foreach ($this->interfaces->interface->iterateItems() as $node) {
            $if = (string)$node->interface;
            if (isset($seen[$if])) {
                $messages->appendMessage(new Message(gettext('An interface is listed twice.'), $node->interface->__reference));
            }
            $seen[$if] = true;
        }

        return $messages;
    }
}
