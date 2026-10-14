workspace "ИС библиотеки" "Учебная модель" {

    model {
        reader    = person "Читатель" "Ищет и бронирует книги"
        librarian = person "Библиотекарь" "Выдаёт книги, ведёт фонд"

        rgb = softwareSystem "Каталог РГБ" "Внешний библиографический источник" "Внешняя"
        sms = softwareSystem "SMS-шлюз" "Уведомления" "Внешняя"
        sso = softwareSystem "SSO вуза" "Аутентификация" "Внешняя"

        lms = softwareSystem "ИС библиотеки" {
            spa    = container "Веб-клиент" "Каталог, личный кабинет, брони" "React"
            desk   = container "АРМ библиотекаря" "Выдача, возврат, приём в фонд" ".NET"
            api    = container "Backend API" "Бизнес-логика" "Kotlin, Spring Boot" {
                circCtrl = component "CirculationController" "REST: выдача, возврат" "Spring MVC"
                catCtrl  = component "CatalogController" "REST: каталог" "Spring MVC"
                circSvc  = component "CirculationService" "Правила выдачи" "Kotlin"
                catSvc   = component "CatalogService" "Поиск книг" "Kotlin"
                fine     = component "FinePolicy" "Расчёт пеней" "Kotlin"
                pub      = component "EventPublisher" "Публикация событий" "Kotlin"
                repo     = component "JPA Repositories" "Доступ к данным" "Spring Data"
            }
            worker = container "Планировщик" "Напоминания, пени" "Kotlin"
            db     = container "Основная БД" "Книги, выдачи, читатели" "PostgreSQL" "Database"
            search = container "Поисковый индекс" "Полнотекстовый поиск" "OpenSearch" "Database"
            bus    = container "Очередь событий" "Доменные события" "RabbitMQ" "Queue"
        }

        reader    -> spa "Пользуется" "HTTPS"
        librarian -> desk "Пользуется" "HTTPS"
        spa       -> api "Вызывает" "JSON/HTTPS"
        desk      -> api "Вызывает" "JSON/HTTPS"
        api       -> db "Читает и пишет" "JDBC"
        api       -> search "Ищет" "HTTP"
        api       -> bus "Публикует события" "AMQP"
        bus       -> worker "Доставляет события" "AMQP"
        worker    -> db "Читает сроки, пишет пени" "JDBC"
        worker    -> sms "Отправляет напоминания" "HTTPS"
        api       -> rgb "Импортирует записи" "HTTPS/OAI-PMH"
        api       -> sso "Проверяет учётки" "OIDC"

        spa -> catCtrl "GET /books" "JSON/HTTPS"
        spa -> circCtrl "POST /loans" "JSON/HTTPS"
        circCtrl -> circSvc "вызывает"
        catCtrl  -> catSvc  "вызывает"
        circSvc  -> fine "использует"
        circSvc  -> pub "публикует LoanCreated"
        circSvc  -> repo "использует"
        catSvc   -> repo "использует"
        catSvc   -> search "запрашивает" "HTTP"
        repo     -> db "читает и пишет" "JDBC"
        pub      -> bus "отправляет" "AMQP"
    }

    views {
        systemContext lms "Context" {
            include *
            autolayout lr
        }
        container lms "Containers" {
            include *
            autolayout lr
        }
        component api "Components" {
            include *
            autolayout lr
        }
        theme default
    }

}