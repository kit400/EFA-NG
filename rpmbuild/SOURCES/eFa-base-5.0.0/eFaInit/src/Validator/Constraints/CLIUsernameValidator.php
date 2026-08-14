<?php

// src/AppBundle/Validator/Constraints/CLIUsernameValidator.php
namespace App\Validator\Constraints;

use Symfony\Component\Process\Process;
use Symfony\Component\Validator\Constraint;
use Symfony\Component\Validator\ConstraintValidator;
use Symfony\Component\Validator\Exception\UnexpectedTypeException;

class CLIUsernameValidator extends ConstraintValidator
{
    public function validate($value, Constraint $constraint): void
    {
        if (!$constraint instanceof CLIUsername) {
            throw new UnexpectedTypeException($constraint, CLIUsername::class);
        }

        // custom constraints should ignore null and empty values to allow
        // other constraints (NotBlank, NotNull, etc.) take care of that
        if (null === $value || '' === $value) {
            return;
        }

        if (!is_string($value)) {
            throw new UnexpectedTypeException($value, 'string');
        }
        
        // Check if username format is valid (Linux username rules)
        if (!preg_match('/^[a-z_][a-z0-9_-]{0,31}$/i', $value)) {
            $this->context->buildViolation($constraint->message)
                ->setParameter('{{ string }}', $value)
                ->addViolation();
            return;
        }

        // Check for reserved or existing system users
        $existingUsers = [
            'root', 'bin', 'daemon', 'adm', 'lp', 'sync', 'shutdown', 'halt', 'mail',
            'operator', 'games', 'ftp', 'nobody', 'systemd-network', 'dbus', 'polkitd',
            'sshd', 'postfix', 'apache', 'mysql', 'clamupdate', 'clamscan', 'mailwatch',
            'mailscanner', 'unbound', 'sqlgrey', 'dcc', 'pyzor', 'razor'
        ];

        if (file_exists('/etc/passwd') && is_readable('/etc/passwd')) {
            $lines = @file('/etc/passwd', FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
            if (is_array($lines)) {
                foreach ($lines as $line) {
                    $parts = explode(':', $line);
                    if (!empty($parts[0])) {
                        $existingUsers[] = strtolower(trim($parts[0]));
                    }
                }
            }
        }

        $existingUsers = array_unique(array_map('strtolower', $existingUsers));

        if (in_array(strtolower($value), $existingUsers, true)) {
            $this->context->buildViolation($constraint->message)
                ->setParameter('{{ string }}', $value)
                ->addViolation();
        }
    }
}

?>
