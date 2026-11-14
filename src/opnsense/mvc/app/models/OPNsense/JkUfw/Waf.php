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
use OPNsense\Core\Config;

/**
 * jk-ufw WAF: protects web servers inside the network that are reachable from the internet.
 *
 * The firewall answers on 80/443 for the published sites (reverse proxy) and checks every request before it
 * reaches the server. The engine is the nginx plugin (os-nginx) with its NAXSI module and the NAXSI core
 * rules; Api\WafController::applyAction() writes these stock nginx objects, all marked "jk-ufw waf: <site>":
 *   - upstream server + upstream (the internal server)
 *   - location "/" with NAXSI on, learning mode for "detect only", the chosen rule groups as policies and
 *     the libinjection SQL/XSS checks
 *   - HTTP server with the site's names, ports, certificate, trusted addresses and bad-bot filter
 * plus pass rules "[jk-ufw waf]" for the two ports on the chosen interfaces.
 */
class Waf extends BaseModel
{
    const TAG = 'jk-ufw waf: ';
    const RULE_TAG = '[jk-ufw waf]';

    /*
     * Rule groups of naxsi_core.rules (the nginx plugin downloads them into policies named after the
     * "## ... ##" headings) and the NAXSI rule ids they cover.
     */
    const GROUPS = [
        'sqli' => ['SQL Injections', [1000, 1099]],
        'rfi' => ['OBVIOUS RFI', [1100, 1199]],
        'traversal' => ['Directory traversal', [1200, 1299]],
        'xss' => ['Cross Site Scripting', [1300, 1399]],
        'evade' => ['Evading tricks', [1400, 1499]],
        'uploads' => ['File uploads', [1500, 1600]],
    ];

    /**
     * Category of a NAXSI rule id (internal ids 17/18 are the libinjection SQL/XSS detectors).
     */
    public static function category($id)
    {
        $id = (int)$id;
        if ($id == 17) {
            return 'sqli';
        }
        if ($id == 18) {
            return 'xss';
        }
        foreach (self::GROUPS as $key => $group) {
            if ($id >= $group[1][0] && $id <= $group[1][1]) {
                return $key;
            }
        }
        return $id < 1000 ? 'protocol' : 'custom';
    }

    /**
     * Split the backend URL: [scheme, host, port].
     */
    public static function backend($url)
    {
        $p = parse_url(trim((string)$url));
        $scheme = strtolower($p['scheme'] ?? 'http');
        $port = $p['port'] ?? ($scheme == 'https' ? 443 : 80);
        return [$scheme, $p['host'] ?? '', (int)$port];
    }

    /**
     * Port the web interface of the firewall itself listens on (it must not be the WAF port).
     */
    public static function guiPorts()
    {
        $gui = Config::getInstance()->object()->system->webgui ?? null;
        $proto = $gui !== null && !empty((string)$gui->protocol) ? (string)$gui->protocol : 'https';
        $port = $gui !== null && !empty((string)$gui->port) ? (int)(string)$gui->port : ($proto == 'https' ? 443 : 80);
        $ports = [$port];
        if ($proto == 'https' && ($gui === null || !isset($gui->disablehttpredirect))) {
            $ports[] = 80; // lighttpd keeps port 80 for the redirect to https
        }
        return ['protocol' => $proto, 'port' => $port, 'ports' => array_values(array_unique($ports))];
    }

    public function performValidation($validateFullModel = false)
    {
        $messages = parent::performValidation($validateFullModel);

        if ((string)$this->general->http_port == (string)$this->general->https_port) {
            $messages->appendMessage(new Message(gettext('HTTP and HTTPS need different ports.'), 'general.https_port'));
        }

        $seen = [];
        foreach ($this->sites->site->iterateItems() as $site) {
            foreach (array_filter(explode(',', strtolower((string)$site->domains))) as $name) {
                if (isset($seen[$name])) {
                    $messages->appendMessage(new Message(
                        sprintf(gettext('%s is already used by another site.'), $name),
                        $site->domains->__reference
                    ));
                }
                $seen[$name] = true;
            }
            if (!$validateFullModel && !$site->isFieldChanged()) {
                continue;
            }
            if ((string)$site->https_only == '1' && (string)$site->certificate === '') {
                $messages->appendMessage(new Message(
                    gettext('"HTTPS only" needs a certificate.'),
                    $site->certificate->__reference
                ));
            }
            [, $host, ] = self::backend((string)$site->backend);
            if (in_array(strtolower($host), ['localhost', '127.0.0.1', '::1'])) {
                $messages->appendMessage(new Message(
                    gettext('The server must be another machine, not the firewall itself.'),
                    $site->backend->__reference
                ));
            }
        }

        return $messages;
    }
}
