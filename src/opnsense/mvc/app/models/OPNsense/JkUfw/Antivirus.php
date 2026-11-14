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
 * jk-ufw: stream antivirus and sandbox.
 *
 * web.*      settings handed to the stock web proxy (Squid), c-icap and ClamAV plugins on apply
 *            (see controllers/OPNsense/JkUfw/Api/AntivirusController.php)
 * files.*    Suricata file extraction; read by templates/OPNsense/IDS/suricata.yaml and scripts/jkufw/av.py
 * intel.*, sandbox.*, action.*   read by scripts/jkufw/av.py (cron worker)
 */
class Antivirus extends BaseModel
{
    public function performValidation($validateFullModel = false)
    {
        $messages = parent::performValidation($validateFullModel);

        if (!$this->web->enabled->isEmpty() && !$this->web->https->isEmpty()) {
            $found = false;
            $ca = (string)$this->web->ca;
            foreach (Config::getInstance()->object()->ca ?? [] as $node) {
                if ((string)$node->refid === $ca && $ca !== '') {
                    $found = true;
                }
            }
            if (!$found) {
                $messages->appendMessage(new Message(
                    gettext('Для проверки HTTPS выберите центр сертификации.'),
                    'web.ca'
                ));
            }
        }
        if (!$this->web->enabled->isEmpty() && empty(trim((string)$this->web->interfaces))) {
            $messages->appendMessage(new Message(gettext('Выберите хотя бы одну сеть.'), 'web.interfaces'));
        }

        $provider = (string)$this->sandbox->provider;
        if (in_array($provider, ['cape', 'cuckoo']) && $this->sandbox->url->isEmpty()) {
            $messages->appendMessage(new Message(gettext('Укажите адрес песочницы.'), 'sandbox.url'));
        }
        if ($provider === 'virustotal' && $this->intel->vt_key->isEmpty()) {
            $messages->appendMessage(new Message(gettext('Для VirusTotal нужен API-ключ.'), 'intel.vt_key'));
        }

        return $messages;
    }
}
