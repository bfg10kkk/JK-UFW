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
 * jk-ufw mail protection: a mail gateway in front of the mail servers inside the network.
 *
 * Mail from the internet arrives at the firewall on port 25, is checked and only then handed to the inside
 * server. The work is done by stock plugins; Api\MailController::applyAction() writes their settings:
 *   - Postfix (os-postfix): relay for the listed domains to their inside servers, strict SMTP checks,
 *     message size limit, rspamd as milter; the inside servers may relay outgoing mail through it
 *   - rspamd (os-rspamd): spam scoring (SPF, DKIM, DMARC, RBL, Bayes, phishing), reject / mark thresholds,
 *     greylisting, dangerous attachment types, the ClamAV antivirus hook
 *   - ClamAV (os-clamav) with freshclam signature updates; Redis (os-redis) when greylisting is on
 * plus pass rules "[jk-ufw mail]" for port 25 on the chosen interfaces.
 */
class Mail extends BaseModel
{
    const RULE_TAG = '[jk-ufw mail]';
    const BAD_EXTENSIONS = 'exe,dll,scr,com,cmd,js,jse,bat,vbs,vbe,ps1,cpl,lnk,msi,msp,reg,hta,iso,img,jar,wsf,docm,xlsm';

    public function performValidation($validateFullModel = false)
    {
        $messages = parent::performValidation($validateFullModel);

        if ((int)(string)$this->general->spam_score >= (int)(string)$this->general->reject_score) {
            $messages->appendMessage(new Message(
                gettext('The "mark as spam" score must be lower than the "refuse" score.'),
                'general.spam_score'
            ));
        }

        $seen = [];
        foreach ($this->domains->domain->iterateItems() as $node) {
            $name = strtolower((string)$node->domain);
            if (isset($seen[$name])) {
                $messages->appendMessage(new Message(
                    sprintf(gettext('%s is listed twice.'), $name),
                    $node->domain->__reference
                ));
            }
            $seen[$name] = true;
        }

        return $messages;
    }
}
