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
use OPNsense\Core\Backend;
use OPNsense\Core\Config;

/**
 * jk-ufw antivirus API (/api/jkufw/antivirus/*).
 *
 * get/set                 settings (model OPNsense/JkUfw/Antivirus)
 * status                  engines, plugins, counters, CAs and interfaces for the page
 * events / files / file   detections, analysed files, one report (scripts/jkufw/av.py)
 * upload (POST multipart) analyse a file from the analyst's computer
 * lookup (POST hash)      reputation of a hash
 * rescan|submit|block|unblock|delete/<sha256>
 * apply (POST)            hand the settings to ClamAV, c-icap and the web proxy, write the port forwards
 *                         "jk-ufw AV: ..." and regenerate Suricata; returns the plugin services the page
 *                         reconfigures next through their own APIs
 */
class AntivirusController extends ApiMutableModelControllerBase
{
    protected static $internalModelClass = '\OPNsense\JkUfw\Antivirus';
    protected static $internalModelName = 'antivirus';

    const NAT_TAG = 'jk-ufw AV:';
    const ICAP_URL = 'icap://[::1]:1344/avscan';
    const PLUGINS = [
        'clamav' => ['class' => '\OPNsense\ClamAV\General', 'package' => 'os-clamav'],
        'cicap' => ['class' => '\OPNsense\CICAP\General', 'package' => 'os-c-icap'],
        'proxy' => ['class' => '\OPNsense\Proxy\Proxy', 'package' => 'os-squid'],
    ];

    private function run($action, $args = [])
    {
        $response = (new Backend())->configdpRun('jkufw_av ' . $action, $args);
        $data = json_decode($response ?? '', true);
        return is_array($data) ? $data : ['error' => gettext('Нет ответа от configd')];
    }

    private function plugins()
    {
        $out = [];
        foreach (self::PLUGINS as $name => $p) {
            $out[$name] = ['installed' => class_exists($p['class']), 'package' => $p['package']];
        }
        return $out;
    }

    public function statusAction()
    {
        $cfg = Config::getInstance()->object();
        $result = $this->run('status');
        $result['plugins'] = $this->plugins();

        $ids = $cfg->OPNsense->IDS->general ?? null;
        $result['ids'] = [
            'enabled' => $ids !== null && (string)$ids->enabled === '1',
            'ips' => $ids !== null && (string)$ids->ips === '1',
            'interfaces' => $ids !== null ? array_filter(explode(',', (string)$ids->interfaces)) : [],
        ];

        $proxy = $cfg->OPNsense->proxy ?? null;
        $result['proxy'] = [
            'enabled' => $proxy !== null && (string)$proxy->general->enabled === '1',
            'icap' => $proxy !== null && (string)$proxy->forward->icap->enable === '1',
            'transparent' => $proxy !== null && (string)$proxy->forward->transparentMode === '1',
            'sslbump' => $proxy !== null && (string)$proxy->forward->sslbump === '1',
        ];
        $result['cicap'] = isset($cfg->OPNsense->cicap) && (string)$cfg->OPNsense->cicap->general->enabled === '1';
        $result['clamav'] = isset($cfg->OPNsense->clamav) && (string)$cfg->OPNsense->clamav->general->enabled === '1';
        $result['nat_rules'] = count($this->natRules());

        $result['cas'] = [];
        foreach ($cfg->ca ?? [] as $ca) {
            if (!empty((string)$ca->prv)) {
                $result['cas'][] = ['refid' => (string)$ca->refid, 'descr' => (string)$ca->descr];
            }
        }
        $result['interfaces'] = [];
        foreach ($cfg->interfaces->children() as $key => $if) {
            if (!empty((string)$if->enable) && empty((string)$if->gateway) && $key !== 'wan' &&
                !in_array((string)$if->ipaddr, ['dhcp', 'pppoe', 'pptp', 'l2tp', ''])) {
                $result['interfaces'][] = ['id' => $key, 'descr' => !empty((string)$if->descr) ? (string)$if->descr : strtoupper($key)];
            }
        }
        return $result;
    }

    public function eventsAction()
    {
        return $this->run('events', ['100']);
    }

    public function filesAction()
    {
        return $this->run('files', ['300']);
    }

    public function fileAction($sha = '')
    {
        return $this->hashOk($sha, 64, true) ? $this->run('file', [strtolower($sha)]) : ['error' => 'bad hash'];
    }

    private function hashOk($v, $len = 64, $any = false)
    {
        return is_string($v) && preg_match($any ? '/^([0-9a-fA-F]{32}|[0-9a-fA-F]{40}|[0-9a-fA-F]{64})$/' :
            '/^[0-9a-fA-F]{' . $len . '}$/', $v);
    }

    private function onHash($action, $sha)
    {
        if (!$this->request->isPost() || !$this->hashOk($sha)) {
            return ['error' => 'bad request'];
        }
        return $this->run($action, [strtolower($sha)]);
    }

    public function rescanAction($sha = '')
    {
        return $this->onHash('rescan', $sha);
    }

    public function submitAction($sha = '')
    {
        return $this->onHash('submit', $sha);
    }

    public function blockAction($sha = '')
    {
        return $this->onHash('block', $sha);
    }

    public function unblockAction($sha = '')
    {
        return $this->onHash('unblock', $sha);
    }

    public function deleteAction($sha = '')
    {
        return $this->onHash('delete', $sha);
    }

    public function lookupAction()
    {
        $hash = trim((string)$this->request->getPost('hash'));
        if (!$this->request->isPost() || !$this->hashOk($hash, 64, true)) {
            return ['error' => gettext('Нужен MD5, SHA-1 или SHA-256.')];
        }
        return $this->run('lookup', [strtolower($hash)]);
    }

    /**
     * POST multipart/form-data, field "file". The file is handed to av.py, which moves it into quarantine.
     */
    public function uploadAction()
    {
        if (!$this->request->isPost() || empty($_FILES['file']) || !is_uploaded_file($_FILES['file']['tmp_name'] ?? '')) {
            return ['error' => gettext('Файл не получен.')];
        }
        if ($_FILES['file']['size'] > 64 * 1024 * 1024) {
            return ['error' => gettext('Файл больше 64 МБ.')];
        }
        $dir = '/var/db/jkufw/av/upload';
        @mkdir($dir, 0700, true);
        $tmp = $dir . '/' . bin2hex(random_bytes(8));
        if (!move_uploaded_file($_FILES['file']['tmp_name'], $tmp)) {
            return ['error' => gettext('Не удалось сохранить файл.')];
        }
        // only safe characters reach the command line; the real name is kept for the report
        $name = preg_replace('/[^\p{L}\p{N}._ ()\-]/u', '_', basename((string)$_FILES['file']['name']));
        $name = mb_substr(trim($name) !== '' ? $name : 'sample', 0, 120);
        return $this->run('upload', [$tmp, str_replace(' ', '_', $name)]);
    }

    /** port forwards owned by this page */
    private function natRules()
    {
        $rules = [];
        $mdl = new \OPNsense\Firewall\DNat();
        foreach ($mdl->rule->iterateItems() as $uuid => $rule) {
            if (strpos((string)$rule->descr, self::NAT_TAG) === 0) {
                $rules[$uuid] = $rule;
            }
        }
        return $rules;
    }

    public function applyAction()
    {
        if (!$this->request->isPost()) {
            return ['status' => 'failed'];
        }
        Config::getInstance()->lock();
        $av = $this->getModel();
        $web = !$av->web->enabled->isEmpty();
        $files = !$av->files->enabled->isEmpty();
        $plugins = $this->plugins();
        $warnings = [];
        $services = [];

        if ($web) {
            $missing = array_values(array_map(fn($p) => $p['package'], array_filter($plugins, fn($p) => !$p['installed'])));
            if ($missing) {
                Config::getInstance()->unlock();
                return ['status' => 'missing', 'packages' => $missing];
            }
        }
        $managed = !$av->web->managed->isEmpty();

        /* ClamAV: the scanner for both the proxy and the files from traffic */
        if ($plugins['clamav']['installed']) {
            $clam = new \OPNsense\ClamAV\General();
            if ($web || $files) {
                $clam->enabled = '1';
                $clam->fc_enabled = '1';
                $clam->enabletcp = '1';
                $services[] = 'clamav';
            } elseif ($managed) {
                $clam->enabled = '0';
                $clam->fc_enabled = '0';
                $services[] = 'clamav';
            }
            $clam->serializeToConfig(false, true);
        } elseif ($files) {
            $warnings[] = gettext('Плагин os-clamav не установлен: файлы из трафика проверяются только по репутации и в песочнице.');
        }

        if ($plugins['cicap']['installed'] && ($web || $managed)) {
            $gen = new \OPNsense\CICAP\General();
            $gen->enabled = $web ? '1' : '0';
            $gen->serializeToConfig(false, true);
            $cav = new \OPNsense\CICAP\Antivirus();
            if ($web) {
                $cav->enable_clamav = '1';
                $cav->maxobjectsize = ((string)$av->web->maxsize) . 'M';
                $cav->passonerror = (string)$av->web->onerror === 'pass' ? '1' : '0';
                $cav->serializeToConfig(false, true);
            }
            $services[] = 'cicap';
        }

        if ($plugins['proxy']['installed'] && ($web || $managed)) {
            $proxy = new \OPNsense\Proxy\Proxy();
            if ($web) {
                if ((string)$proxy->general->enabled !== '1') {
                    $av->web->managed = '1';
                    $proxy->general->enabled = '1';
                }
                $proxy->forward->interfaces = (string)$av->web->interfaces;
                $proxy->forward->transparentMode = '1';
                $proxy->forward->sslbump = (string)$av->web->https;
                if (!$av->web->https->isEmpty()) {
                    $proxy->forward->sslcertificate = (string)$av->web->ca;
                    $proxy->forward->sslurlonly = '0';
                }
                $proxy->forward->sslnobumpsites = (string)$av->web->nobump;
                $proxy->forward->icap->enable = '1';
                $proxy->forward->icap->RequestURL = self::ICAP_URL;
                $proxy->forward->icap->ResponseURL = self::ICAP_URL;
            } else {
                $proxy->forward->icap->enable = '0';
                $proxy->forward->transparentMode = '0';
                $proxy->forward->sslbump = '0';
                $proxy->general->enabled = '0';
                $av->web->managed = '0';
            }
            $proxy->serializeToConfig(false, true);
            $services[] = 'proxy';
        }

        /* port forwards: LAN :80 (and :443) -> local proxy, the firewall itself excluded */
        $nat = new \OPNsense\Firewall\DNat();
        $own = [];
        foreach ($nat->rule->iterateItems() as $uuid => $rule) {
            if (strpos((string)$rule->descr, self::NAT_TAG) === 0) {
                $own[] = $uuid;
            }
        }
        foreach ($own as $uuid) {
            $nat->rule->del($uuid);
        }
        if ($web) {
            $ports = ['80' => ['3128', 'HTTP']];
            if (!$av->web->https->isEmpty()) {
                $ports['443'] = ['3129', 'HTTPS'];
            }
            foreach (array_filter(explode(',', (string)$av->web->interfaces)) as $if) {
                foreach ($ports as $port => [$local, $label]) {
                    $r = $nat->rule->Add();
                    $r->setNodes([
                        'interface' => $if,
                        'ipprotocol' => 'inet',
                        'protocol' => 'tcp',
                        'source' => ['network' => $if, 'not' => '0'],
                        'destination' => ['network' => '(self)', 'not' => '1', 'port' => $port],
                        'target' => '127.0.0.1',
                        'local-port' => $local,
                        'pass' => 'pass',
                        'descr' => sprintf('%s %s -> antivirus proxy (%s)', self::NAT_TAG, $label, $if),
                    ]);
                }
            }
        }
        $natMsgs = $nat->performValidation();
        foreach ($natMsgs as $msg) {
            $warnings[] = sprintf('NAT: %s', $msg->getMessage());
        }
        if (!count($natMsgs)) {
            $nat->serializeToConfig(false, true);
        }

        $av->serializeToConfig(false, true);
        Config::getInstance()->save();

        $backend = new Backend();
        $backend->configdRun('filter reload');
        $backend->configdRun('cron restart');

        /* Suricata: file-store output + extraction / hash rules */
        $yaml = @file_get_contents('/usr/local/etc/suricata/suricata.yaml') ?: '';
        $had = strpos($yaml, 'file-store:') !== false;
        $backend->configdRun('template reload OPNsense/IDS');
        $sync = json_decode($backend->configdRun('jkufw_av sync') ?? '', true);
        $ids = Config::getInstance()->object()->OPNsense->IDS->general ?? null;
        if ($ids !== null && (string)$ids->enabled === '1') {
            if ($had !== $files) {
                $backend->configdRun('ids restart');
            }
        } elseif ($files) {
            $warnings[] = gettext('Система обнаружения вторжений выключена: файлы из трафика не извлекаются, пока её не включить.');
        }

        return ['status' => 'ok', 'services' => array_values(array_unique($services)), 'warnings' => $warnings,
            'sync' => $sync];
    }
}
