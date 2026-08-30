#!/usr/bin/php
<?php
/**
 * eFa-Migrate Configuration Audit & Merge Engine
 * Compares source configs with defaults and merges user-selected parameters.
 * Copyright (C) 2026 EFA-NG Project (https://efa-ng.space.ua)
 */

if (php_sapi_name() !== 'cli') {
    die("CLI only.\n");
}

function get_php_constants($file) {
    if (!file_exists($file)) return [];
    $cmd = sprintf("php -r %s 2>/dev/null", escapeshellarg("require " . var_export($file, true) . "; echo json_encode(get_defined_constants(true)['user'] ?? []);"));
    $res = shell_exec($cmd);
    return json_decode($res, true) ?: [];
}

function parse_key_value_file($file, $delimiter = '=') {
    if (!file_exists($file)) return [];
    $lines = file($file, FILE_IGNORE_NEW_LINES);
    $res = [];
    foreach ($lines as $line) {
        $trimmed = trim($line);
        if ($trimmed === '' || $trimmed[0] === '#') continue;
        $parts = explode($delimiter, $trimmed, 2);
        if (count($parts) === 2) {
            $k = trim($parts[0]);
            $v = trim($parts[1]);
            $res[$k] = $v;
        }
    }
    return $res;
}

function audit_conf_php($srcFile) {
    $exampleFiles = [
        '/var/www/html/mailscanner/conf.php.example',
        '/var/www/html/mailscanner/conf.php.rpmnew',
        '/var/www/html/mailscanner/conf.php'
    ];
    $exampleFile = null;
    foreach ($exampleFiles as $ef) {
        if (file_exists($ef)) {
            $exampleFile = $ef;
            break;
        }
    }

    $src = get_php_constants($srcFile);
    $def = $exampleFile ? get_php_constants($exampleFile) : [];

    $ignore = ['DB_PASS', 'DB_USER', 'DB_DSN', 'DB_HOST', 'DB_NAME', 'SESSION_NAME'];
    $diffs = [];

    foreach ($src as $k => $v) {
        if (in_array($k, $ignore, true)) continue;
        $defVal = $def[$k] ?? null;

        if (!array_key_exists($k, $def) || $defVal !== $v) {
            $diffs[] = [
                'key' => $k,
                'src' => $v,
                'def' => $defVal ?? '(not set in default)'
            ];
        }
    }
    return $diffs;
}

function audit_mailscanner($srcFile) {
    $targetFile = '/etc/MailScanner/MailScanner.conf';
    $src = parse_key_value_file($srcFile);
    $tgt = parse_key_value_file($targetFile);

    $ignore = [
        'Run As User', 'Run As Group', 'Incoming Queue Dir', 'Outgoing Queue Dir',
        'Quarantine Dir', 'PID Directory', 'Lock File', 'Monitors For Free Space'
    ];

    $diffs = [];
    foreach ($src as $k => $v) {
        if (in_array($k, $ignore, true)) continue;
        $tgtVal = $tgt[$k] ?? null;
        if ($tgtVal !== null && $tgtVal !== $v) {
            $diffs[] = [
                'key' => $k,
                'src' => $v,
                'def' => $tgtVal
            ];
        }
    }
    return $diffs;
}

function audit_postfix($srcPostconfFile) {
    $src = parse_key_value_file($srcPostconfFile);
    $ignore = [
        'myhostname', 'mydomain', 'myorigin', 'inet_interfaces', 'inet_protocols',
        'queue_directory', 'command_directory', 'daemon_directory', 'data_directory',
        'mail_owner', 'setgid_group', 'html_directory', 'manpage_directory',
        'sample_directory', 'readme_directory', 'shlib_directory', 'meta_directory',
        'alias_database', 'alias_maps'
    ];

    $diffs = [];
    foreach ($src as $k => $v) {
        if (in_array($k, $ignore, true)) continue;
        $curVal = trim(shell_exec(sprintf("postconf -h %s 2>/dev/null", escapeshellarg($k))) ?? '');
        $defVal = trim(shell_exec(sprintf("postconf -d -h %s 2>/dev/null", escapeshellarg($k))) ?? '');

        if ($v !== $defVal && $v !== $curVal) {
            $diffs[] = [
                'key' => $k,
                'src' => $v,
                'def' => $defVal !== '' ? $defVal : $curVal
            ];
        }
    }
    return $diffs;
}

function audit_spamassassin($srcFile) {
    $targetFile = '/etc/mail/spamassassin/local.cf';
    $srcLines = file_exists($srcFile) ? file($srcFile, FILE_IGNORE_NEW_LINES) : [];
    $tgtContent = file_exists($targetFile) ? file_get_contents($targetFile) : '';

    $diffs = [];
    foreach ($srcLines as $line) {
        $t = trim($line);
        if ($t === '' || $t[0] === '#') continue;
        if (strpos($tgtContent, $t) === false) {
            $parts = preg_split('/\s+/', $t, 2);
            $key = $parts[0] ?? $t;
            $val = $parts[1] ?? '';
            $diffs[] = [
                'key' => $key . ($val !== '' ? ' ' . $val : ''),
                'src' => $t,
                'def' => '(not present)'
            ];
        }
    }
    return $diffs;
}

function get_all_diffs($srcDir) {
    return [
        'conf_php' => audit_conf_php("$srcDir/conf.php"),
        'mailscanner' => audit_mailscanner("$srcDir/MailScanner.conf"),
        'postfix' => audit_postfix("$srcDir/postfix_postconf_n.txt"),
        'spamassassin' => audit_spamassassin("$srcDir/local.cf")
    ];
}

// -----------------------------------------------------------------------------
// Interactive Review Function
// -----------------------------------------------------------------------------
function review_type_menu($type, $srcDir) {
    $diffs = get_all_diffs($srcDir);
    $items = $diffs[$type] ?? [];

    if (empty($items)) {
        echo "\n \033[33m[INFO] No custom or non-default parameters found for $type.\033[0m\n";
        sleep(1);
        return;
    }

    $selFile = "$srcDir/selected_{$type}.json";
    $selectedKeys = [];
    if (file_exists($selFile)) {
        $selectedKeys = json_decode(file_get_contents($selFile), true) ?: [];
    } else {
        // Default: all selected
        foreach ($items as $it) {
            $selectedKeys[] = $it['key'];
        }
    }

    $titles = [
        'conf_php' => 'conf.php (MailWatch GUI Settings)',
        'mailscanner' => 'MailScanner.conf (Filter Engine Directives)',
        'postfix' => 'main.cf (Postfix Mail Transport Parameters)',
        'spamassassin' => 'local.cf (SpamAssassin Custom Rules & Scores)'
    ];
    $title = $titles[$type] ?? $type;

    while (true) {
        echo "\033[2J\033[H";
        echo "\033[36m┌────────────────────────────────────────────────────────────────────────┐\033[0m\n";
        printf("\033[36m│\033[0m  \033[1m%-68.68s\033[0m  \033[36m│\033[0m\n", "REVIEW CUSTOMIZATIONS: " . $title);
        echo "\033[36m├────────────────────────────────────────────────────────────────────────┤\033[0m\n";
        echo "\033[36m│\033[0m  Toggle individual parameters to migrate [1-" . count($items) . "], then press [C]: \033[36m│\033[0m\n";
        echo "\033[36m└────────────────────────────────────────────────────────────────────────┘\033[0m\n\n";

        foreach ($items as $idx => $it) {
            $num = $idx + 1;
            $isChecked = in_array($it['key'], $selectedKeys, true);
            $mark = $isChecked ? "\033[32m[✔]\033[0m" : "\033[31m[ ]\033[0m";

            $srcVal = is_bool($it['src']) ? ($it['src'] ? 'true' : 'false') : json_encode($it['src'], JSON_UNESCAPED_SLASHES);
            $defVal = is_bool($it['def']) ? ($it['def'] ? 'true' : 'false') : json_encode($it['def'], JSON_UNESCAPED_SLASHES);

            if (strlen($srcVal) > 35) $srcVal = substr($srcVal, 0, 32) . '...';
            if (strlen($defVal) > 25) $defVal = substr($defVal, 0, 22) . '...';

            printf("  %s %2d. \033[1m%-26.26s\033[0m = %-35s \033[2m(def: %s)\033[0m\n", $mark, $num, $it['key'], $srcVal, $defVal);
        }

        echo "\n";
        echo "  \033[1mA)\033[0m Select All    \033[1mN)\033[0m Deselect All    \033[1mC)\033[0m \033[32mConfirm & Save Selection\033[0m\n\n";
        echo " \033[32m[eFa-NG]\033[0m Choice [1-" . count($items) . ", A, N, C]: ";

        $line = trim(fgets(STDIN));
        if (strcasecmp($line, 'c') === 0) {
            file_put_contents($selFile, json_encode(array_values($selectedKeys)));
            echo "\n \033[32m✔ Saved " . count($selectedKeys) . " selected parameters for $type.\033[0m\n";
            sleep(1);
            break;
        } elseif (strcasecmp($line, 'a') === 0) {
            $selectedKeys = [];
            foreach ($items as $it) $selectedKeys[] = $it['key'];
        } elseif (strcasecmp($line, 'n') === 0) {
            $selectedKeys = [];
        } elseif (is_numeric($line)) {
            $num = (int)$line;
            if ($num >= 1 && $num <= count($items)) {
                $targetKey = $items[$num - 1]['key'];
                $keyIdx = array_search($targetKey, $selectedKeys, true);
                if ($keyIdx !== false) {
                    unset($selectedKeys[$keyIdx]);
                } else {
                    $selectedKeys[] = $targetKey;
                }
            }
        }
    }
}

// -----------------------------------------------------------------------------
// Action Router
// -----------------------------------------------------------------------------
$action = $argv[1] ?? 'summary';
$srcDir = $argv[2] ?? '';

switch ($action) {
    case 'summary':
        $all = get_all_diffs($srcDir);
        $summary = [
            'conf_php' => count($all['conf_php']),
            'mailscanner' => count($all['mailscanner']),
            'postfix' => count($all['postfix']),
            'spamassassin' => count($all['spamassassin']),
            'total' => count($all['conf_php']) + count($all['mailscanner']) + count($all['postfix']) + count($all['spamassassin'])
        ];
        echo json_encode($summary);
        break;

    case 'select-all':
        $all = get_all_diffs($srcDir);
        foreach ($all as $t => $list) {
            $keys = array_column($list, 'key');
            file_put_contents("$srcDir/selected_{$t}.json", json_encode($keys));
        }
        echo "OK\n";
        break;

    case 'select-none':
        foreach (['conf_php', 'mailscanner', 'postfix', 'spamassassin'] as $t) {
            file_put_contents("$srcDir/selected_{$t}.json", json_encode([]));
        }
        echo "OK\n";
        break;

    case 'review':
        $type = $argv[3] ?? 'conf_php';
        review_type_menu($type, $srcDir);
        break;

    case 'apply':
        echo "Applying selected configurations...\n";

        // 1. conf.php
        $selConfFile = "$srcDir/selected_conf_php.json";
        if (file_exists($selConfFile) && file_exists("$srcDir/conf.php") && file_exists('/var/www/html/mailscanner/conf.php')) {
            $keys = json_decode(file_get_contents($selConfFile), true) ?: [];
            if (!empty($keys)) {
                $srcConsts = get_php_constants("$srcDir/conf.php");
                $content = file_get_contents('/var/www/html/mailscanner/conf.php');
                foreach ($keys as $k) {
                    if (!array_key_exists($k, $srcConsts)) continue;
                    $val = $srcConsts[$k];
                    $export = var_export($val, true);
                    $pattern = "/define\(\s*['\"]" . preg_quote($k, '/') . "['\"]\s*,\s*.*?\);/s";

                    if (preg_match($pattern, $content)) {
                        $content = preg_replace($pattern, "define('" . $k . "', " . $export . ");", $content, 1);
                    } else {
                        $content .= "\ndefine('" . $k . "', " . $export . ");\n";
                    }
                }
                file_put_contents('/var/www/html/mailscanner/conf.php', $content);
                echo " - conf.php: updated " . count($keys) . " custom settings.\n";
            }
        }

        // 2. MailScanner.conf
        $selMsFile = "$srcDir/selected_mailscanner.json";
        if (file_exists($selMsFile) && file_exists("$srcDir/MailScanner.conf") && file_exists('/etc/MailScanner/MailScanner.conf')) {
            $keys = json_decode(file_get_contents($selMsFile), true) ?: [];
            if (!empty($keys)) {
                $srcDirectives = parse_key_value_file("$srcDir/MailScanner.conf");
                $lines = file('/etc/MailScanner/MailScanner.conf', FILE_IGNORE_NEW_LINES);

                foreach ($keys as $k) {
                    if (!array_key_exists($k, $srcDirectives)) continue;
                    $val = $srcDirectives[$k];
                    $pattern = "/^(\s*" . preg_quote($k, '/') . "\s*=).*$/";
                    $found = false;

                    foreach ($lines as $idx => $line) {
                        if (preg_match($pattern, $line)) {
                            $lines[$idx] = $k . ' = ' . $val;
                            $found = true;
                            break;
                        }
                    }
                    if (!$found) {
                        $lines[] = $k . ' = ' . $val;
                    }
                }
                file_put_contents('/etc/MailScanner/MailScanner.conf', implode("\n", $lines) . "\n");
                echo " - MailScanner.conf: updated " . count($keys) . " directives.\n";
            }
        }

        // 3. Postfix main.cf
        $selPfFile = "$srcDir/selected_postfix.json";
        if (file_exists($selPfFile) && file_exists("$srcDir/postfix_postconf_n.txt")) {
            $keys = json_decode(file_get_contents($selPfFile), true) ?: [];
            if (!empty($keys)) {
                $srcParams = parse_key_value_file("$srcDir/postfix_postconf_n.txt");
                foreach ($keys as $k) {
                    if (!array_key_exists($k, $srcParams)) continue;
                    $val = $srcParams[$k];
                    system(sprintf("postconf -e %s", escapeshellarg("$k = $val")));
                }
                echo " - Postfix: applied " . count($keys) . " custom parameters.\n";
            }
        }

        // 4. SpamAssassin local.cf
        $selSaFile = "$srcDir/selected_spamassassin.json";
        if (file_exists($selSaFile) && file_exists("$srcDir/local.cf") && file_exists('/etc/mail/spamassassin/local.cf')) {
            $keys = json_decode(file_get_contents($selSaFile), true) ?: [];
            if (!empty($keys)) {
                $srcLines = file("$srcDir/local.cf", FILE_IGNORE_NEW_LINES);
                $tgtContent = file_get_contents('/etc/mail/spamassassin/local.cf');

                foreach ($keys as $k) {
                    foreach ($srcLines as $line) {
                        $t = trim($line);
                        if ($t === '' || $t[0] === '#') continue;
                        if (strpos($t, $k) === 0 && strpos($tgtContent, $t) === false) {
                            $tgtContent .= "\n" . $t . "\n";
                        }
                    }
                }
                file_put_contents('/etc/mail/spamassassin/local.cf', $tgtContent);
                echo " - SpamAssassin: merged " . count($keys) . " custom rules.\n";
            }
        }

        echo "All selected configurations merged.\n";
        break;

    default:
        echo "Usage: eFa-Migrate-Audit.php [summary|review|select-all|select-none|apply] <srcDir> [type]\n";
        exit(1);
}
