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

use OPNsense\Core\Backend;
use OPNsense\Core\Config;
use OPNsense\Firewall\DNat;
use OPNsense\Firewall\Filter;

/**
 * Helpers shared by the jk-ufw "published service" pages (WAF, mail protection): which add-on packages are
 * installed and running, pass rules that open a service port on the outside interfaces, and port forwards
 * that would send the same traffic around the firewall.
 */
class Publish
{
    /**
     * Is the plugin installed (its model class is there) and is the daemon running?
     * @param string $class model class of the plugin, e.g. '\OPNsense\Nginx\Nginx'
     * @param string $service configd service name, e.g. 'nginx'
     */
    public static function component($pkg, $class, $service)
    {
        $installed = class_exists($class);
        $running = false;
        if ($installed) {
            $out = (string)(new Backend())->configdRun("{$service} status");
            $running = stripos($out, 'is running') !== false;
        }
        return ['package' => $pkg, 'installed' => $installed, 'running' => $running];
    }

    /**
     * Interfaces a service can be published on: [{name, descr, wan}], outside (has a gateway) first.
     */
    public static function interfaces()
    {
        $result = [];
        $cfg = Config::getInstance()->object();
        if (!isset($cfg->interfaces)) {
            return $result;
        }
        foreach ($cfg->interfaces->children() as $name => $node) {
            if (empty((string)$node->enable) && $name != 'wan') {
                continue;
            }
            if (in_array($name, ['lo0', 'openvpn', 'wireguard', 'enc0']) || !empty((string)$node->virtual)) {
                continue;
            }
            $wan = $name == 'wan' || !empty((string)$node->gateway) || in_array((string)$node->ipaddr, ['dhcp', 'pppoe']);
            $result[] = [
                'name' => $name,
                'descr' => !empty((string)$node->descr) ? (string)$node->descr : strtoupper($name),
                'wan' => $wan,
            ];
        }
        usort($result, fn($a, $b) => $b['wan'] <=> $a['wan']);
        return $result;
    }

    /**
     * Replace the pass rules carrying $tag: one per interface and port, "to this firewall's address on that
     * interface". Empty $ports removes them. Caller saves the config.
     * @return int number of rules written
     */
    public static function syncRules($tag, $interfaces, $ports, $label)
    {
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
        $cfg = Config::getInstance()->object();
        $count = 0;
        foreach ($interfaces as $if) {
            if (!isset($cfg->interfaces->$if)) {
                continue;
            }
            foreach ($ports as $port) {
                $filter->rules->rule->Add()->setNodes([
                    'enabled' => '1', 'action' => 'pass', 'quick' => '1', 'interface' => $if, 'direction' => 'in',
                    'ipprotocol' => 'inet46', 'protocol' => 'TCP', 'source_net' => 'any', 'source_not' => '0',
                    'destination_net' => "{$if}ip", 'destination_not' => '0', 'destination_port' => (string)$port,
                    'log' => '0', 'description' => "{$tag} {$label} {$port}",
                ]);
                $count++;
            }
        }
        $filter->serializeToConfig();
        return $count;
    }

    /**
     * Number of our pass rules in the config.
     */
    public static function countRules($tag)
    {
        $count = 0;
        foreach ((new Filter())->rules->rule->iterateItems() as $rule) {
            if (str_starts_with((string)$rule->description, $tag) && (string)$rule->enabled == '1') {
                $count++;
            }
        }
        return $count;
    }

    /**
     * Port forwards on the given ports: they hand the traffic to an inside host before the gateway sees it.
     * @return array [{port, interface, target, descr}]
     */
    public static function portForwards($ports)
    {
        $result = [];
        if (!class_exists('\OPNsense\Firewall\DNat')) {
            return $result;
        }
        foreach ((new DNat())->rule->iterateItems() as $rule) {
            if (!empty((string)$rule->disabled) || !empty((string)$rule->nordr)) {
                continue;
            }
            $dport = (string)$rule->destination->port;
            foreach ($ports as $port) {
                if (self::portMatches($dport, (int)$port)) {
                    $result[] = [
                        'port' => (int)$port,
                        'interface' => (string)$rule->interface,
                        'target' => (string)$rule->target,
                        'descr' => (string)$rule->descr,
                    ];
                }
            }
        }
        return $result;
    }

    private static function portMatches($spec, $port)
    {
        foreach (explode(',', $spec) as $part) {
            $part = trim($part);
            if ($part === '') {
                continue;
            }
            if (preg_match('/^(\d+)[:\-](\d+)$/', $part, $m)) {
                if ($port >= (int)$m[1] && $port <= (int)$m[2]) {
                    return true;
                }
            } elseif (ctype_digit($part) && (int)$part == $port) {
                return true;
            } elseif (!ctype_digit($part) && getservbyname($part, 'tcp') === $port) {
                return true;
            }
        }
        return false;
    }

    /**
     * Last $max lines of a file without reading all of it.
     */
    public static function tail($file, $max = 2000)
    {
        if (!is_readable($file) || ($size = filesize($file)) === 0) {
            return [];
        }
        $fh = fopen($file, 'r');
        $chunk = min($size, 512 * 1024);
        fseek($fh, -$chunk, SEEK_END);
        $data = fread($fh, $chunk);
        fclose($fh);
        $lines = explode("\n", rtrim($data, "\n"));
        if ($chunk < $size) {
            array_shift($lines); // partial first line
        }
        return array_slice($lines, -$max);
    }
}
