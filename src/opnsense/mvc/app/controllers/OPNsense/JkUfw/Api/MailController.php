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
use OPNsense\JkUfw\Mail;
use OPNsense\JkUfw\Publish;

/**
 * jk-ufw mail protection API (/api/jkufw/mail/*).
 *
 * get/set            general settings (on/off, name, thresholds, checks)
 * *Domain            mail domains and the inside server each one is delivered to
 * status             components, rspamd counters and history, ClamAV signatures, mail queue, conflicts
 * apply (POST)       write the Postfix / rspamd / ClamAV / Redis settings and the pass rules
 *                    (see models/OPNsense/JkUfw/Mail.php); the page then reconfigures each service
 */
class MailController extends ApiMutableModelControllerBase
{
    protected static $internalModelClass = '\OPNsense\JkUfw\Mail';
    protected static $internalModelName = 'mail';

    const POSTFIX = '\OPNsense\Postfix\General';
    const POSTFIX_DOMAIN = '\OPNsense\Postfix\Domain';
    const POSTFIX_ANTISPAM = '\OPNsense\Postfix\Antispam';
    const RSPAMD = '\OPNsense\Rspamd\RSpamd';
    const CLAMAV = '\OPNsense\ClamAV\General';
    const REDIS = '\OPNsense\Redis\Redis';
    const RSPAMD_URL = 'http://127.0.0.1:11334';
    const LOOPBACK = ['127.0.0.0/8', '[::ffff:127.0.0.0]/104', '[::1]/128'];

    public function searchDomainAction()
    {
        return $this->searchBase('domains.domain', ['enabled', 'domain', 'server', 'port', 'description']);
    }

    public function getDomainAction($uuid = null)
    {
        return $this->getBase('domain', 'domains.domain', $uuid);
    }

    public function addDomainAction()
    {
        return $this->addBase('domain', 'domains.domain');
    }

    public function setDomainAction($uuid)
    {
        return $this->setBase('domain', 'domains.domain', $uuid);
    }

    public function delDomainAction($uuid)
    {
        return $this->delBase('domains.domain', $uuid);
    }

    public function toggleDomainAction($uuid, $enabled = null)
    {
        return $this->toggleBase('domains.domain', $uuid, $enabled);
    }

    private function components()
    {
        $mdl = $this->getModel();
        $list = [
            'postfix' => Publish::component('os-postfix', self::POSTFIX, 'postfix'),
            'rspamd' => Publish::component('os-rspamd', self::RSPAMD, 'rspamd'),
            'clamav' => Publish::component('os-clamav', self::CLAMAV, 'clamav'),
            'redis' => Publish::component('os-redis', self::REDIS, 'redis'),
        ];
        $list['postfix']['needed'] = true;
        $list['rspamd']['needed'] = true;
        $list['clamav']['needed'] = (string)$mdl->general->antivirus == '1';
        $list['redis']['needed'] = (string)$mdl->general->greylist == '1';
        return $list;
    }

    private static function rspamd($path)
    {
        $ch = curl_init(self::RSPAMD_URL . $path);
        curl_setopt_array($ch, [CURLOPT_RETURNTRANSFER => true, CURLOPT_TIMEOUT => 3, CURLOPT_CONNECTTIMEOUT => 1]);
        $body = curl_exec($ch);
        $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        return $code == 200 ? json_decode($body, true) : null;
    }

    /**
     * rspamd history row -> event
     */
    public static function historyRow($row)
    {
        $symbols = [];
        foreach ($row['symbols'] ?? [] as $name => $sym) {
            $score = (float)($sym['score'] ?? 0);
            if ($score > 0) {
                $symbols[$name] = $score;
            }
        }
        arsort($symbols);
        $rcpt = $row['rcpt_mime'] ?? ($row['rcpt_smtp'] ?? []);
        $action = (string)($row['action'] ?? '');
        return [
            'time' => (int)($row['unix_time'] ?? 0),
            'from' => (string)($row['sender_mime'] ?? ($row['sender_smtp'] ?? '')),
            'to' => is_array($rcpt) ? implode(', ', $rcpt) : (string)$rcpt,
            'subject' => mb_substr((string)($row['subject'] ?? ''), 0, 160),
            'ip' => (string)($row['ip'] ?? ''),
            'size' => (int)($row['size'] ?? 0),
            'score' => round((float)($row['score'] ?? 0), 1),
            'action' => $action,
            'virus' => isset($row['symbols']['CLAM_VIRUS']) ? (string)($row['symbols']['CLAM_VIRUS']['options'][0] ?? 'virus') : null,
            'attachment' => isset($row['symbols']['BAD_FILE_EXTENSION']) || isset($row['symbols']['MIME_BAD_EXTENSION']),
            'reasons' => array_slice(array_keys($symbols), 0, 4),
        ];
    }

    public function statusAction()
    {
        $mdl = $this->getModel();
        $result = [
            'components' => $this->components(),
            'interfaces' => Publish::interfaces(),
            'forwards' => Publish::portForwards([25]),
            'applied' => Publish::countRules(Mail::RULE_TAG),
            'hostname' => '',
            'stats' => null,
            'events' => [],
            'queue' => null,
            'signatures' => null,
            'now' => time(),
        ];
        $sys = Config::getInstance()->object()->system;
        $result['hostname'] = trim((string)$sys->hostname . '.' . (string)$sys->domain, '.');

        if ($result['components']['rspamd']['running']) {
            $stat = self::rspamd('/stat');
            if (is_array($stat)) {
                $actions = $stat['actions'] ?? [];
                $result['stats'] = [
                    'scanned' => (int)($stat['scanned'] ?? 0),
                    'rejected' => (int)($actions['reject'] ?? 0),
                    'spam' => (int)($actions['add header'] ?? 0) + (int)($actions['rewrite subject'] ?? 0),
                    'greylisted' => (int)($actions['greylist'] ?? 0) + (int)($actions['soft reject'] ?? 0),
                    'clean' => (int)($actions['no action'] ?? 0),
                    'learned' => (int)($stat['learned'] ?? 0),
                    'uptime' => (int)($stat['uptime'] ?? 0),
                ];
            }
            $hist = self::rspamd('/history');
            $rows = is_array($hist) ? ($hist['rows'] ?? $hist) : [];
            $viruses = 0;
            foreach (is_array($rows) ? $rows : [] as $row) {
                if (is_array($row)) {
                    $ev = self::historyRow($row);
                    $viruses += $ev['virus'] !== null ? 1 : 0;
                    $result['events'][] = $ev;
                }
            }
            usort($result['events'], fn($a, $b) => $b['time'] <=> $a['time']);
            $result['events'] = array_slice($result['events'], 0, 60);
            if ($result['stats'] !== null) {
                $result['stats']['viruses'] = $viruses;
            }
        }
        if ($result['components']['clamav']['running']) {
            $ver = json_decode((string)(new Backend())->configdRun('clamav version'), true);
            if (is_array($ver)) {
                $result['signatures'] = [
                    'daily' => (string)($ver['daily.cld'] ?? ($ver['daily.cvd'] ?? '')),
                    'total' => (string)($ver['Total number of signatures'] ?? ''),
                    'version' => (string)($ver['Version'] ?? ''),
                ];
            }
        }
        if ($result['components']['postfix']['running'] && is_executable('/usr/local/sbin/postqueue')) {
            $out = (string)shell_exec('/usr/local/sbin/postqueue -j 2>/dev/null');
            $result['queue'] = count(array_filter(explode("\n", $out)));
        }
        return $result;
    }

    private static function check($mdl, $name)
    {
        foreach ($mdl->performValidation() as $msg) {
            throw new UserException(sprintf('%s: %s (%s)', $name, $msg->getMessage(), $msg->getField()), 'Mail');
        }
        $mdl->serializeToConfig(false, true);
    }

    public function applyAction()
    {
        if (!$this->request->isPost()) {
            return ['status' => 'failed'];
        }
        $mdl = $this->getModel();
        $g = $mdl->general;
        $enabled = (string)$g->enabled == '1';
        $av = (string)$g->antivirus == '1';
        $grey = (string)$g->greylist == '1';
        $missing = [];
        foreach ($this->components() as $c) {
            if ($c['needed'] && !$c['installed']) {
                $missing[] = $c['package'];
            }
        }
        if ($enabled && !empty($missing)) {
            throw new UserException(sprintf(gettext('Install first: %s'), implode(', ', $missing)), 'Mail');
        }

        Config::getInstance()->lock();
        $this->throwReadOnly();

        $domains = [];
        foreach ($mdl->domains->domain->iterateItems() as $d) {
            if ((string)$d->enabled == '1') {
                $domains[] = [strtolower((string)$d->domain), (string)$d->server, (string)$d->port];
            }
        }
        $on = $enabled && !empty($domains);

        if (!class_exists(self::POSTFIX)) {
            /* turned off and never installed: only our own rules and settings to tidy up */
            $mdl->serializeToConfig(false, true);
            Publish::syncRules(Mail::RULE_TAG, [], [], 'smtp');
            Config::getInstance()->save();
            (new Backend())->configdRun('filter reload');
            return ['status' => 'ok', 'domains' => 0, 'rules' => 0, 'reconfigure' => []];
        }

        /* Postfix: relay for our domains to the inside servers */
        $cls = self::POSTFIX_DOMAIN;
        $pd = new $cls();
        $managed = array_filter(explode(',', (string)$g->managed));
        $del = [];
        foreach ($pd->domains->domain->iterateItems() as $uuid => $node) {
            if (in_array(strtolower((string)$node->domainname), $managed)) {
                $del[] = $uuid;
            }
        }
        foreach ($del as $uuid) {
            $pd->domains->domain->del($uuid);
        }
        $servers = [];
        foreach ($on ? $domains : [] as [$name, $server, $port]) {
            $host = filter_var($server, FILTER_VALIDATE_IP) ? "[{$server}]" : $server;
            $pd->domains->domain->Add()->setNodes([
                'enabled' => '1', 'domainname' => $name, 'destination' => "{$host}:{$port}",
            ]);
            if (filter_var($server, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4)) {
                $servers[] = "{$server}/32";
            } elseif (filter_var($server, FILTER_VALIDATE_IP, FILTER_FLAG_IPV6)) {
                $servers[] = "[{$server}]/128";
            }
        }
        self::check($pd, 'Postfix');
        $g->managed = implode(',', $on ? array_column($domains, 0) : []);

        $cls = self::POSTFIX;
        $pf = new $cls();
        $strict = (string)$g->strict == '1' ? '1' : '0';
        $pf->setNodes([
            'enabled' => $on ? '1' : '0',
            'myhostname' => (string)$g->hostname,
            'mynetworks' => implode(',', array_merge(self::LOOPBACK, (string)$g->outbound == '1' ? array_unique($servers) : [])),
            'message_size_limit' => (string)((int)(string)$g->max_size * 1024 * 1024),
            'reject_unauth_destination' => '1',
            'permit_mynetworks' => '1',
            'reject_unauth_pipelining' => '1',
            'reject_non_fqdn_helo_hostname' => $strict,
            'reject_invalid_helo_hostname' => $strict,
            'reject_unknown_sender_domain' => $strict,
            'reject_unknown_recipient_domain' => $strict,
            'reject_non_fqdn_sender' => $strict,
            'reject_non_fqdn_recipient' => $strict,
        ]);
        if ($on && (string)$pf->mydomain === '') {
            $pf->mydomain = $domains[0][0];
        }
        self::check($pf, 'Postfix');

        $cls = self::POSTFIX_ANTISPAM;
        $pa = new $cls();
        /* tempfail: while rspamd is down, senders retry later instead of mail passing unchecked */
        $pa->setNodes(['enable_rspamd' => $on ? '1' : '0', 'default_action' => 'tempfail']);
        self::check($pa, 'Postfix');

        $services = [];
        if (class_exists(self::REDIS) && $grey && $on) {
            $cls = self::REDIS;
            $rd = new $cls();
            $rd->general->enabled = '1';
            self::check($rd, 'Redis');
            $services[] = ['url' => '/api/redis/service/reconfigure', 'name' => 'Redis'];
        }
        if (class_exists(self::CLAMAV)) {
            $cls = self::CLAMAV;
            $ca = new $cls();
            $ca->enabled = $on && $av ? '1' : '0';
            $ca->fc_enabled = $on && $av ? '1' : '0';
            self::check($ca, 'ClamAV');
            if ($on && $av) {
                $services[] = ['url' => '/api/clamav/service/freshclam', 'name' => 'ClamAV', 'freshclam' => true];
            }
            $services[] = ['url' => '/api/clamav/service/reconfigure', 'name' => 'ClamAV'];
        }
        if (class_exists(self::RSPAMD)) {
            $cls = self::RSPAMD;
            $rs = new $cls();
            $spam = (int)(string)$g->spam_score;
            $rs->setNodes([
                'general' => [
                    'enabled' => $on ? '1' : '0',
                    'rejectscore' => (string)$g->reject_score,
                    'headerscore' => (string)$spam,
                    'greylistscore' => $grey ? (string)max(1, $spam - 2) : '',
                    /*
                     * The plugin writes add_header only together with a subject score, so mark the subject of
                     * clear spam halfway between "mark as spam" and "refuse".
                     */
                    'subjectscore' => (string)intdiv($spam + (int)(string)$g->reject_score + 1, 2),
                    'rewritesubject' => '[SPAM]',
                    'enable_redis_plugin' => $grey ? '1' : (string)$rs->general->enable_redis_plugin,
                ],
                'milter_headers' => ['enabled' => '1', 'enable_spamd_bar' => '1', 'enable_authentication_results' => '1'],
                'av' => ['force-reject' => '1', 'attachments-only' => '1'],
                'multimap' => [
                    'badfileextension' => (string)$g->attachments == '1' ? Mail::BAD_EXTENSIONS : '',
                    'whitelistsender' => (string)$g->allow_senders,
                ],
                'phishing' => ['openphish_enabled' => (string)$g->phishing],
            ]);
            self::check($rs, 'rspamd');
            $services[] = ['url' => '/api/rspamd/service/reconfigure', 'name' => 'rspamd'];
        }
        $services[] = ['url' => '/api/postfix/service/reconfigure', 'name' => 'Postfix'];

        $mdl->serializeToConfig(false, true);
        $ifs = array_filter(explode(',', (string)$g->interfaces));
        $rules = Publish::syncRules(Mail::RULE_TAG, $ifs, $on ? ['25'] : [], 'smtp');
        Config::getInstance()->save();
        $status = trim((new Backend())->configdRun('filter reload'));
        return ['status' => 'ok', 'domains' => $on ? count($domains) : 0, 'rules' => $rules, 'filter' => $status,
            'reconfigure' => $services];
    }
}
