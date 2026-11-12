# Reply to Arno (eFa Project Creator) regarding EFA-NG

## Original Message from Arno
```text
Hi Yuri (Kit),

The forums are currently in a read-only state due to constant bot spam, which is why you are seeing the 404 error. While we are keeping the site and forums online for reference, we have stepped back from developing eFa due to time constraints.

When I started eFa years ago, I had much more free time. Since then, a busy day job and family life have taken priority. Our philosophy was always to keep eFa free to download, meaning it remained an unpaid side project. Over time, watching commercial parties monetize the project while demanding new features and bug fixes—without contributing back—also became a real burden. Shawn stepped in over the last few years and took on the public-facing role, but he eventually ran into the exact same challenges.

Beyond the time commitment, eFa cannot continue in its current state because it relies heavily on aging open-source components that require a complete architectural overhaul:

    MailScanner: Unmaintained upstream. We took over maintenance for a while, but the codebase is outdated and needs a complete rewrite.

    MailWatch: Also unmaintained and requires a ground-up rewrite.

    Apache SpamAssassin: Still maintained to keep the lights on, but no new features are being developed.

While AI tools could probably help speed up a rewrite, Shawn and I are sysadmins rather than software developers. We built eFa by integrating existing projects, and maintaining the underlying codebases ourselves simply became unsustainable. At one point, we discussed migrating the core to Rspamd and building a new system around it, but we never had the bandwidth to fully explore it.

I really appreciate your effort in keeping eFa alive, and I don't want to sound discouraging. However, without a concrete plan to refactor the core architecture, any continuation of the project will likely hit a dead end down the road. It is definitely worth carefully evaluating which underlying components you want to keep and how they are tied together moving forward.

Regards,

Arno
```

---

## English Reply (Ready to Send)

**Subject:** Re: eFa Project & EFA-NG continuation

Hi Arno,

Thank you very much for taking the time to write back with such an honest, thoughtful, and detailed reply. 

First and foremost, I want to express my deepest gratitude to you and Shawn. What you created and maintained for so many years has protected countless mail servers around the world. I completely understand your frustration with commercial entities taking advantage of free open-source work without contributing back, as well as the need to prioritize family and career. You both did a phenomenal job, and stepping back under those circumstances is entirely understandable.

Your words about being sysadmins rather than programmers really resonated with me. I am not a software developer either — I am a system administrator from Ukraine. In between work, keeping critical infrastructure running, and daily challenges here, maintaining and upgrading eFa has been my passion project. 

I completely agree with your technical assessment regarding the aging core components. Over the past months, by combining sysadmin domain knowledge with modern AI development tooling, we managed to achieve what previously felt out of reach for a small team:
- Fully ported the stack to **Enterprise Linux 10 (CentOS Stream 10)** with **PHP 8.4** and **Perl 5.40**.
- Built a comprehensive automated test suite and static analysis (PHPStan / PHPUnit) for MailWatch to clean up legacy technical debt, SQL injection vulnerabilities, and race conditions.
- Replaced legacy iptables with clean native `nftables` automation, updated OpenDKIM/DMARC handling, and signed all packages with our own GPG repository.

You are spot on about the future: in the long run, transitioning towards a more modern engine like Rspamd will be essential. Right now, our primary mission with **EFA-NG** is to give existing users and admins a secure, maintained, modern drop-in path on current operating systems so their setups don't hit a wall.

Since the eFa forum is currently locked in read-only mode, ordinary users cannot start new threads. Would you or Shawn be willing to post a brief pinned announcement or note on the forum (or on the website) letting the community know that an active continuation exists? 

If you are open to this, here are the project details you could reference:
- **Project Name:** EFA-NG (Next Generation)
- **Website:** https://efa-ng.space.ua
- **GitHub Organization / Repositories:** https://github.com/kit400/EFA-NG
- **Telegram Community:** https://t.me/EFA_NG

I would be truly honored to carry the torch forward and ensure that the legacy you built continues to serve the open-source community.

Thank you again for everything, and I wish you and Shawn the very best in your work, health, and family life.

Warm regards,

Yuri (Kit)  
System Administrator  
EFA-NG Project  

---

## Russian Translation (For Reference)

**Тема:** Re: eFa Project & EFA-NG continuation

Привет, Арно,

Большое спасибо за то, что нашел время ответить так искренне, взвешенно и подробно.

Прежде всего хочу выразить глубочайшую благодарность тебе и Шону. То, что вы создали и поддерживали столько лет, защитило бесчисленное количество почтовых серверов по всему миру. Я прекрасно понимаю ваше разочарование коммерческими компаниями, которые паразитируют на бесплатном open-source и ничего не отдают взамен, а также необходимость ставить семью и работу на первое место. Вы проделали колоссальную работу, и ваше решение отойти от дел в этих обстоятельствах более чем понятно.

Твои слова о том, что вы скорее сисадмины, чем программисты, нашли у меня полный отклик. Я тоже не разработчик — я системный администратор из Украины. Между работой, поддержанием критической инфраструктуры и повседневными вызовами здесь, поддержка и обновление eFa стали проектом для души.

Я абсолютно согласен с твоей технической оценкой насчет устаревания базовых компонентов. За последние месяцы, объединив опыт системного администрирования с современными AI-инструментами разработки, нам удалось сделать то, что раньше казалось неподъемным для одного человека/небольшой команды:
- Полностью перенесли стек на **Enterprise Linux 10 (CentOS Stream 10)** с **PHP 8.4** и **Perl 5.40**.
- Написали полноценный набор автоматических тестов и статического анализа (PHPStan / PHPUnit) для MailWatch, закрыв старый технический долг, уязвимости SQLi и race conditions.
- Заменили устаревший iptables на чистый нативный `nftables`, обновили логику OpenDKIM/DMARC и перешли на собственный подписанный GPG-репозиторий.

Ты абсолютно прав насчет будущего: в долгосрочной перспективе переход на современный движок вроде Rspamd неизбежен. Но прямо сейчас главная задача **EFA-NG** — дать существующим пользователям и администраторам безопасный, поддерживаемый и современный путь миграции на актуальные ОС, чтобы их почтовые шлюзы не превратились в «кирпичи».

Поскольку форум eFa сейчас переведен в read-only режим из-за ботов, обычные пользователи не могут создать тему. Не мог бы ты или Шон опубликовать короткое закрепленное объявление на форуме (или на сайте), чтобы сообщество знало, что проект продолжает жить в виде EFA-NG?

Если вы не против, вот основные ссылки:
- **Название:** EFA-NG (Next Generation)
- **Сайт:** https://efa-ng.space.ua
- **GitHub:** https://github.com/kit400/EFA-NG
- **Telegram-сообщество:** https://t.me/EFA_NG

Для меня будет честью продолжить ваше дело и сделать так, чтобы созданное вами наследие продолжало приносить пользу сообществу.

Еще раз спасибо за всё. Желаю тебе и Шону крепкого здоровья, успехов в работе и благополучия в семьях.

С наилучшими пожеланиями,  
Юрий (Kit)  
Системный администратор  
Проект EFA-NG  
