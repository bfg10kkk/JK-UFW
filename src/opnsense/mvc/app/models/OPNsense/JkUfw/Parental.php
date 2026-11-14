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
 * jk-ufw parental control: per device "no internet" windows (e.g. 23:00-07:00 on school nights) and an instant pause.
 *
 * The model only stores what the user picked. Api\ParentalController::applyAction() turns it into stock objects:
 * one alias and one schedule per device and a pair of floating filter rules, so nothing new runs in the packet path.
 */
class Parental extends BaseModel
{
    /* prefix of every alias, schedule and rule description this feature owns; everything with it is regenerated */
    const PREFIX = 'jkufw_';
    const RULE_TAG = '[jk-ufw]';

    /**
     * Aliases and schedules of this feature are named jkufw_<12 hex digits of the device uuid>. Other jk-ufw
     * features use the same jkufw_ prefix (jkufw_geoblock, jkufw_private, jkufw_sdwan_*, jkufw_appctl_*), so
     * only names of exactly this shape may be removed as stale.
     */
    public static function isOwnName($name)
    {
        return preg_match('/^' . self::PREFIX . '[0-9a-f]{12}$/', $name) === 1;
    }

    public static function isMac($value)
    {
        return preg_match('/^([0-9a-f]{2}[:-]){5}[0-9a-f]{2}$/i', $value) === 1;
    }

    public function performValidation($validateFullModel = false)
    {
        $messages = parent::performValidation($validateFullModel);
        foreach ($this->devices->device->iterateItems() as $node) {
            if (!$validateFullModel && !$node->isFieldChanged()) {
                continue;
            }
            $items = array_filter(explode(',', (string)$node->addresses));
            $macs = array_filter($items, [self::class, 'isMac']);
            if (count($macs) > 0 && count($macs) != count($items)) {
                $messages->appendMessage(new Message(
                    gettext('Use either IP addresses or MAC addresses for one device, not both.'),
                    $node->addresses->__reference
                ));
            }
        }
        return $messages;
    }

    /**
     * Minutes of the day [from, to) during which internet is allowed, per ISO weekday (1 = Monday).
     * A block window that ends before it starts (23:00-07:00) runs over midnight into the next day;
     * equal times block the whole 24 hours from that moment.
     * @return array weekday => list of [from, to] in minutes, to <= 1440
     */
    public static function allowedRanges(array $days, $from, $to)
    {
        $min = function ($hhmm) {
            [$h, $m] = array_map('intval', explode(':', $hhmm));
            return $h * 60 + $m;
        };
        $f = $min($from);
        $t = $min($to);
        $blocked = array_fill(1, 7, []);
        foreach ($days as $day) {
            $day = (int)$day;
            if ($day < 1 || $day > 7) {
                continue;
            }
            $next = $day % 7 + 1;
            if ($f < $t) {
                $blocked[$day][] = [$f, $t];
            } else {
                $blocked[$day][] = [$f, 1440];
                if ($t > 0) {
                    $blocked[$next][] = [0, $t];
                }
            }
        }
        $result = [];
        foreach ($blocked as $day => $ranges) {
            usort($ranges, fn($a, $b) => $a[0] <=> $b[0]);
            $allowed = [];
            $cursor = 0;
            foreach ($ranges as [$bf, $bt]) {
                if ($bf > $cursor) {
                    $allowed[] = [$cursor, $bf];
                }
                $cursor = max($cursor, $bt);
            }
            if ($cursor < 1440) {
                $allowed[] = [$cursor, 1440];
            }
            $result[$day] = $allowed;
        }
        return $result;
    }

    /**
     * Is internet allowed at the given ISO weekday and minute of the day, for ranges from allowedRanges()?
     */
    public static function allowedAt(array $ranges, $weekday, $minute)
    {
        foreach ($ranges[$weekday] ?? [] as [$f, $t]) {
            if ($minute >= $f && $minute < $t) {
                return true;
            }
        }
        return false;
    }

    /**
     * Same as allowedRanges(), shaped as <timerange> entries of a legacy firewall schedule:
     * days with identical hours are merged into one entry with a "position" list.
     */
    public static function scheduleTimeranges(array $days, $from, $to)
    {
        $fmt = fn($m) => sprintf('%d:%02d', intdiv($m, 60), $m % 60);
        $byHours = [];
        foreach (self::allowedRanges($days, $from, $to) as $day => $ranges) {
            foreach ($ranges as [$rf, $rt]) {
                $byHours[$fmt($rf) . '-' . $fmt($rt)][] = $day;
            }
        }
        $result = [];
        foreach ($byHours as $hours => $weekdays) {
            $result[] = ['position' => implode(',', $weekdays), 'hour' => $hours, 'rangedescr' => 'internet allowed'];
        }
        return $result;
    }
}
