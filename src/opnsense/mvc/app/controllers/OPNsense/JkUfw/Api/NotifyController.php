<?php

/*
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

/**
 * jk-ufw: Telegram notifications API, /api/jkufw/notify/*
 */
class NotifyController extends ApiMutableModelControllerBase
{
    protected static $internalModelName = 'notify';
    protected static $internalModelClass = 'OPNsense\JkUfw\Notify';

    /**
     * the watcher runs from cron only while enabled, so the crontab follows the setting
     */
    public function reconfigureAction()
    {
        if ($this->request->isPost()) {
            (new Backend())->configdRun('cron restart');
            return ['status' => 'ok'];
        }
        return ['status' => 'failed'];
    }

    /**
     * send a test message with the saved token and chat
     */
    public function testAction()
    {
        if ($this->request->isPost()) {
            return $this->runScript('jkufw notify test');
        }
        return ['status' => 'failed'];
    }

    /**
     * list chats that wrote to the bot recently (Telegram getUpdates), to pick a chat ID
     */
    public function chatsAction()
    {
        if ($this->request->isPost()) {
            return $this->runScript('jkufw notify chats');
        }
        return ['status' => 'failed'];
    }

    /**
     * watcher state: last run, last error, counters
     */
    public function statusAction()
    {
        return $this->runScript('jkufw notify status');
    }

    private function runScript($action)
    {
        $response = json_decode((new Backend())->configdRun($action) ?? '', true);
        return is_array($response) ? $response : ['status' => 'error', 'message' => gettext('No response from configd')];
    }
}
