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
use OPNsense\Core\Backend;
use OPNsense\Core\Config;
use OPNsense\JkUfw\Publish;
use OPNsense\JkUfw\Waf;

/**
 * jk-ufw WAF API (/api/jkufw/waf/*).
 *
 * get/set            general settings (on/off, interfaces, ports, trusted addresses)
 * *Site              protected sites (names, inside server, certificate, mode, rule groups)
 * status             components, port conflicts, attacks seen in the nginx logs (NAXSI), per-site counters
 * apply (POST)       write the nginx objects and pass rules (see models/OPNsense/JkUfw/Waf.php); the page then
 *                    calls /api/nginx/service/reconfigure
 * rules (POST)       download the NAXSI core rules into the nginx plugin (once)
 * movegui (POST)     move the firewall's own web interface to another port, so 80/443 are free for the sites
 */
class WafController extends ApiMutableModelControllerBase
{
    protected static $internalModelClass = '\OPNsense\JkUfw\Waf';
    protected static $internalModelName = 'waf';

    const NGINX = '\OPNsense\Nginx\Nginx';
    const LOG_GLOB = '/var/log/nginx/*error.log';

    public function searchSiteAction()
    {
        return $this->searchBase(
            'sites.site',
            ['enabled', 'domains', 'backend', 'mode', 'rules', 'certificate', 'https_only', 'description']
        );
    }

    public function getSiteAction($uuid = null)
    {
        return $this->getBase('site', 'sites.site', $uuid);
    }

    public function addSiteAction()
    {
        return $this->addBase('site', 'sites.site');
    }

    public function setSiteAction($uuid)
    {
        return $this->setBase('site', 'sites.site', $uuid);
    }

    public function delSiteAction($uuid)
    {
        return $this->delBase('sites.site', $uuid);
    }

    public function toggleSiteAction($uuid, $enabled = null)
    {
        return $this->toggleBase('sites.site', $uuid, $enabled);
    }

    /**
     * NAXSI policies of the nginx plugin per rule group: [group key => policy uuid]
     */
    private function policies($ngx)
    {
        $result = [];
        foreach ($ngx->custom_policy->iterateItems() as $uuid => $pol) {
            foreach (Waf::GROUPS as $key => $group) {
                if (!isset($result[$key]) && stripos((string)$pol->name, $group[0]) === 0) {
                    $result[$key] = $uuid;
                }
            }
        }
        return $result;
    }

    private function certificates()
    {
        $result = [];
        $cfg = Config::getInstance()->object();
        foreach ($cfg->cert ?? [] as $cert) {
            if (empty((string)$cert->prv) || empty((string)$cert->crt)) {
                continue;
            }
            $info = @openssl_x509_parse(base64_decode((string)$cert->crt));
            $result[] = [
                'refid' => (string)$cert->refid,
                'descr' => (string)$cert->descr,
                'cn' => $info['subject']['CN'] ?? '',
                'san' => $info['extensions']['subjectAltName'] ?? '',
                'expires' => isset($info['validTo_time_t']) ? (int)$info['validTo_time_t'] : null,
            ];
        }
        return $result;
    }

    /**
     * NAXSI log lines -> events, newest first.
     */
    private function events($since)
    {
        $events = [];
        foreach (glob(self::LOG_GLOB) ?: [] as $file) {
            foreach (Publish::tail($file, 3000) as $line) {
                $ev = self::parseLine($line);
                if ($ev !== null && $ev['time'] >= $since) {
                    $events[] = $ev;
                }
            }
        }
        usort($events, fn($a, $b) => $b['time'] <=> $a['time']);
        return $events;
    }

    /**
     * One nginx error log line with a NAXSI report, e.g.
     * 2026/11/14 10:01:02 [error] 811#100140: *77 NAXSI_FMT: ip=203.0.113.9&server=shop.example.com&uri=/item
     *   &vers=1.6&total_processed=40&total_blocked=3&config=block&cscore0=$policy..&score0=8&zone0=ARGS
     *   &id0=1000&var_name0=id, client: 203.0.113.9, server: shop.example.com, request: "GET /item?id=.. HTTP/1.1"
     */
    public static function parseLine($line)
    {
        if (strpos($line, 'NAXSI_FMT: ') === false) {
            return null;
        }
        if (!preg_match('/^(\d{4}\/\d\d\/\d\d \d\d:\d\d:\d\d) .*?NAXSI_FMT: ([^ ,]+)(.*)$/', $line, $m)) {
            return null;
        }
        $f = [];
        parse_str(str_replace(['$', '+'], ['%24', '%2B'], $m[2]), $f);
        $request = preg_match('/request: "([^"]*)"/', $m[3], $r) ? $r[1] : '';
        $method = $request !== '' ? strtok($request, ' ') : '';
        $ids = [];
        $cats = [];
        $where = [];
        for ($i = 0; isset($f["id{$i}"]); $i++) {
            $ids[] = (int)$f["id{$i}"];
            $cats[] = Waf::category($f["id{$i}"]);
            $zone = $f["zone{$i}"] ?? '';
            $var = $f["var_name{$i}"] ?? '';
            $where[] = $var !== '' ? "{$zone}:{$var}" : $zone;
        }
        $config = (string)($f['config'] ?? '');
        $learning = stripos($config, 'learning') !== false || ($f['learning'] ?? '0') === '1';
        $time = \DateTime::createFromFormat('Y/m/d H:i:s', $m[1]);
        return [
            'time' => $time ? $time->getTimestamp() : 0,
            'ip' => (string)($f['ip'] ?? ''),
            'server' => (string)($f['server'] ?? ''),
            'uri' => (string)($f['uri'] ?? ''),
            'method' => $method,
            'request' => mb_substr($request, 0, 300),
            'ids' => array_values(array_unique($ids)),
            'category' => $cats[0] ?? 'custom',
            'categories' => array_values(array_unique($cats)),
            'where' => array_values(array_unique(array_filter($where))),
            'blocked' => !$learning,
        ];
    }

    public function statusAction()
    {
        $mdl = $this->getModel();
        $result = [
            'components' => [Publish::component('os-nginx', self::NGINX, 'nginx')],
            'gui' => Waf::guiPorts(),
            'interfaces' => Publish::interfaces(),
            'certificates' => $this->certificates(),
            'rules_loaded' => false,
            'applied' => Publish::countRules(Waf::RULE_TAG),
            'other_sites' => 0,
        ];
        $ports = [(int)(string)$mdl->general->http_port, (int)(string)$mdl->general->https_port];
        $result['gui']['conflict'] = array_values(array_intersect($ports, $result['gui']['ports']));
        $result['forwards'] = Publish::portForwards($ports);

        if (class_exists(self::NGINX)) {
            $cls = self::NGINX;
            $ngx = new $cls();
            $result['rules_loaded'] = count($this->policies($ngx)) > 0;
            foreach ($ngx->http_server->iterateItems() as $uuid => $srv) {
                if (!in_array($uuid, explode(',', (string)$mdl->general->managed))) {
                    $result['other_sites']++;
                }
            }
        }

        /* attacks of the last 24 hours */
        $now = time();
        $since = $now - 86400;
        $events = $this->events($since);
        $sites = [];
        foreach ($mdl->sites->site->iterateItems() as $uuid => $site) {
            $sites[$uuid] = ['names' => array_filter(explode(',', strtolower((string)$site->domains))),
                'blocked' => 0, 'detected' => 0, 'last' => null];
        }
        $hourly = array_fill(0, 24, 0);
        $byCat = [];
        $ips = [];
        $blocked = 0;
        foreach ($events as &$ev) {
            $ev['site'] = null;
            foreach ($sites as $uuid => $s) {
                if (in_array(strtolower($ev['server']), $s['names'])) {
                    $ev['site'] = $uuid;
                    $sites[$uuid][$ev['blocked'] ? 'blocked' : 'detected']++;
                    $sites[$uuid]['last'] = max($sites[$uuid]['last'] ?? 0, $ev['time']);
                    break;
                }
            }
            $h = (int)floor(($now - $ev['time']) / 3600);
            if ($h >= 0 && $h < 24) {
                $hourly[23 - $h]++;
            }
            $byCat[$ev['category']] = ($byCat[$ev['category']] ?? 0) + 1;
            $ips[$ev['ip']] = ($ips[$ev['ip']] ?? 0) + 1;
            $blocked += $ev['blocked'] ? 1 : 0;
        }
        unset($ev);
        arsort($ips);
        $top = [];
        foreach (array_slice($ips, 0, 6, true) as $ip => $n) {
            $top[] = ['ip' => (string)$ip, 'count' => $n];
        }
        $result['stats'] = [
            'total' => count($events), 'blocked' => $blocked, 'detected' => count($events) - $blocked,
            'attackers' => count($ips), 'by_category' => $byCat, 'top_ips' => $top, 'hourly' => $hourly,
        ];
        foreach ($sites as &$s) {
            unset($s['names']);
        }
        $result['sites'] = $sites;
        $result['events'] = array_slice($events, 0, 60);
        $result['now'] = $now;
        return $result;
    }

    /**
     * Load the NAXSI core rules into the nginx plugin (its own downloader). Must run without the config lock:
     * the downloader is a separate process that saves the config itself.
     */
    public function rulesAction()
    {
        if (!$this->request->isPost() || !class_exists(self::NGINX)) {
            return ['status' => 'failed'];
        }
        $cls = self::NGINX;
        if (count($this->policies(new $cls())) == 0) {
            (new Backend())->configdRun('nginx naxsidownloadrules');
            Config::getInstance()->forceReload();
        }
        $loaded = count($this->policies(new $cls()));
        return ['status' => $loaded > 0 ? 'ok' : 'failed', 'groups' => $loaded];
    }

    /**
     * Write the nginx objects of every site and the pass rules; the page then reconfigures nginx.
     */
    public function applyAction()
    {
        if (!$this->request->isPost()) {
            return ['status' => 'failed'];
        }
        if (!class_exists(self::NGINX)) {
            throw new UserException(gettext('Install the nginx plugin (os-nginx) first.'), 'WAF');
        }
        Config::getInstance()->lock();
        $this->throwReadOnly();
        $mdl = $this->getModel();
        $enabled = (string)$mdl->general->enabled == '1';
        $cls = self::NGINX;
        $ngx = new $cls();
        $policies = $this->policies($ngx);
        if ($enabled && empty($policies)) {
            throw new UserException(gettext('The WAF rules are not loaded yet.'), 'WAF');
        }

        /* take out what we wrote last time */
        $managed = array_filter(explode(',', (string)$mdl->general->managed));
        foreach (['http_server', 'location', 'upstream', 'upstream_server'] as $type) {
            $del = [];
            foreach ($ngx->$type->iterateItems() as $uuid => $node) {
                $descr = isset($node->description) ? (string)$node->description : '';
                if (in_array($uuid, $managed) || str_starts_with($descr, Waf::TAG)) {
                    $del[] = $uuid;
                }
            }
            foreach ($del as $uuid) {
                $ngx->$type->del($uuid);
            }
        }

        $servers = [];
        $count = 0;
        if ($enabled) {
            $http = (string)$mdl->general->http_port;
            $https = (string)$mdl->general->https_port;
            $trusted = (string)$mdl->general->trusted;
            foreach ($mdl->sites->site->iterateItems() as $site) {
                if ((string)$site->enabled != '1') {
                    continue;
                }
                $names = (string)$site->domains;
                $tag = Waf::TAG . explode(',', $names)[0];
                [$scheme, $host, $port] = Waf::backend((string)$site->backend);

                $us = $ngx->upstream_server->Add();
                $us->setNodes(['description' => $tag, 'server' => $host, 'port' => (string)$port, 'priority' => '1']);
                $up = $ngx->upstream->Add();
                $up->setNodes([
                    'description' => $tag,
                    'serverentries' => $us->getAttributes()['uuid'],
                    'tls_enable' => $scheme == 'https' ? '1' : '0',
                    'tls_verify' => '0',
                ]);

                $rules = array_filter(explode(',', (string)$site->rules));
                $pol = [];
                foreach ($rules as $r) {
                    if (isset($policies[$r])) {
                        $pol[] = $policies[$r];
                    }
                }
                $loc = $ngx->location->Add();
                $loc->setNodes([
                    'description' => $tag,
                    'urlpattern' => '/',
                    'enable_secrules' => '1',
                    'enable_learning_mode' => (string)$site->mode == 'block' ? '0' : '1',
                    'custom_policy' => implode(',', $pol),
                    'sqli_block_score' => in_array('sqli', $rules) ? '8' : '',
                    'xss_block_score' => in_array('xss', $rules) ? '8' : '',
                    'upstream' => $up->getAttributes()['uuid'],
                    'max_body_size' => (string)$site->max_body . 'm',
                    'websocket' => (string)$site->websocket,
                ]);

                $cert = (string)$site->certificate;
                $srv = $ngx->http_server->Add();
                $srv->setNodes([
                    'servername' => $names,
                    'listen_http_address' => "{$http},[::]:{$http}",
                    'listen_https_address' => $cert !== '' ? "{$https},[::]:{$https}" : '',
                    'certificate' => $cert,
                    'https_only' => $cert !== '' && (string)$site->https_only == '1' ? '1' : '0',
                    'locations' => $loc->getAttributes()['uuid'],
                    'disable_bot_protection' => (string)$site->bots == '1' ? '0' : '1',
                    'naxsi_whitelist_srcip' => $trusted,
                    'enable_acme_support' => '1',
                ]);
                $servers[] = $srv->getAttributes()['uuid'];
                $count++;
            }
        }
        /* nginx runs while it has any server: ours or ones set up by hand */
        $ngx->general->enabled = count(iterator_to_array($ngx->http_server->iterateItems())) > 0
            || count(iterator_to_array($ngx->stream_server->iterateItems())) > 0 ? '1' : '0';

        $msgs = $ngx->performValidation();
        foreach ($msgs as $msg) {
            /* only the objects written above are new, so a message here is about one of our sites */
            throw new UserException(sprintf('nginx: %s (%s)', $msg->getMessage(), $msg->getField()), 'WAF');
        }
        $ngx->serializeToConfig(false, true);

        $mdl->general->managed = implode(',', $servers);
        $mdl->serializeToConfig(false, true);

        $ports = $enabled && $count > 0 ? [(string)$mdl->general->http_port, (string)$mdl->general->https_port] : [];
        $ifs = array_filter(explode(',', (string)$mdl->general->interfaces));
        $rules = Publish::syncRules(Waf::RULE_TAG, $ifs, $ports, 'web');
        Config::getInstance()->save();

        $status = trim((new Backend())->configdRun('filter reload'));
        return ['status' => 'ok', 'sites' => $count, 'rules' => $rules, 'filter' => $status,
            'reconfigure' => ['/api/nginx/service/reconfigure']];
    }

    /**
     * Move the firewall's web interface off the WAF ports (default 8443), restart it after 3 seconds.
     */
    public function moveguiAction()
    {
        if (!$this->request->isPost()) {
            return ['status' => 'failed'];
        }
        $port = (int)$this->request->getPost('port', 'int', 8443);
        $mdl = $this->getModel();
        $busy = [(int)(string)$mdl->general->http_port, (int)(string)$mdl->general->https_port, 25];
        if ($port < 1024 || $port > 65535 || in_array($port, $busy)) {
            throw new UserException(gettext('Choose a free port from 1024 to 65535.'), 'WAF');
        }
        Config::getInstance()->lock();
        $this->throwReadOnly();
        $cfg = Config::getInstance()->object();
        if (!isset($cfg->system->webgui)) {
            $cfg->system->addChild('webgui');
        }
        $gui = $cfg->system->webgui;
        $gui->port = (string)$port;
        if (!isset($gui->disablehttpredirect)) {
            $gui->addChild('disablehttpredirect', '1');
        }
        Config::getInstance()->save();
        (new Backend())->configdpRun('webgui restart', [3], true);
        (new Backend())->configdRun('filter reload', true);
        return ['status' => 'ok', 'port' => $port, 'protocol' => Waf::guiPorts()['protocol']];
    }
}
