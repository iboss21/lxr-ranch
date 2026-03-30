/* ============================================================================
   wolves.land NUI - LXR Ranch Dashboard
   Vanilla JS | No jQuery | No React
   ============================================================================ */

(function () {
    'use strict';

    // -------------------------------------------------------------------------
    // State
    // -------------------------------------------------------------------------
    var ranchData = {
        overview: {
            animals: 0,
            staff: 0,
            storageUsed: 0,
            storageMax: 0,
            dailyIncome: 0,
            level: 1,
            reputation: 0,
            status: 'No ranch data available.',
            activity: []
        },
        animals: [],
        production: [],
        staff: [],
        storage: {
            capacity: 0,
            maxCapacity: 0,
            items: []
        },
        economy: {
            updated: '--',
            prices: []
        }
    };

    var isOpen = false;
    var activeTab = 'overview';

    // -------------------------------------------------------------------------
    // DOM References
    // -------------------------------------------------------------------------
    var app = document.getElementById('wl-app');
    var tabButtons = document.querySelectorAll('.wl-tabs__btn');
    var tabPanels = document.querySelectorAll('.wl-content__panel');

    // -------------------------------------------------------------------------
    // NUI Communication
    // -------------------------------------------------------------------------
    function postAction(action, data) {
        fetch('https://lxr-ranch/' + action, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data || {})
        }).catch(function () {});
    }

    // -------------------------------------------------------------------------
    // Tab Switching
    // -------------------------------------------------------------------------
    function switchTab(tabName) {
        activeTab = tabName;

        for (var i = 0; i < tabButtons.length; i++) {
            if (tabButtons[i].getAttribute('data-tab') === tabName) {
                tabButtons[i].classList.add('active');
            } else {
                tabButtons[i].classList.remove('active');
            }
        }

        for (var j = 0; j < tabPanels.length; j++) {
            if (tabPanels[j].id === 'tab-' + tabName) {
                tabPanels[j].classList.add('active');
            } else {
                tabPanels[j].classList.remove('active');
            }
        }
    }

    for (var i = 0; i < tabButtons.length; i++) {
        tabButtons[i].addEventListener('click', function () {
            switchTab(this.getAttribute('data-tab'));
        });
    }

    // -------------------------------------------------------------------------
    // Open / Close UI
    // -------------------------------------------------------------------------
    function openUI(data) {
        if (data) {
            updateRanchData(data);
        }
        isOpen = true;
        app.classList.remove('closing');
        app.classList.add('visible');
        switchTab('overview');
        renderAll();
    }

    function closeUI() {
        if (!isOpen) return;
        isOpen = false;
        app.classList.add('closing');
        setTimeout(function () {
            app.classList.remove('visible');
            app.classList.remove('closing');
        }, 250);
        postAction('close');
    }

    // -------------------------------------------------------------------------
    // ESC Key
    // -------------------------------------------------------------------------
    document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape' || e.key === 'Backspace') {
            closeUI();
        }
    });

    // -------------------------------------------------------------------------
    // Data Management
    // -------------------------------------------------------------------------
    function updateRanchData(data) {
        if (!data) return;

        if (data.overview) {
            var o = data.overview;
            ranchData.overview.animals = o.animals !== undefined ? o.animals : ranchData.overview.animals;
            ranchData.overview.staff = o.staff !== undefined ? o.staff : ranchData.overview.staff;
            ranchData.overview.storageUsed = o.storageUsed !== undefined ? o.storageUsed : ranchData.overview.storageUsed;
            ranchData.overview.storageMax = o.storageMax !== undefined ? o.storageMax : ranchData.overview.storageMax;
            ranchData.overview.dailyIncome = o.dailyIncome !== undefined ? o.dailyIncome : ranchData.overview.dailyIncome;
            ranchData.overview.level = o.level !== undefined ? o.level : ranchData.overview.level;
            ranchData.overview.reputation = o.reputation !== undefined ? o.reputation : ranchData.overview.reputation;
            ranchData.overview.status = o.status || ranchData.overview.status;
            ranchData.overview.activity = o.activity || ranchData.overview.activity;
        }
        if (data.animals) {
            ranchData.animals = data.animals;
        }
        if (data.production) {
            ranchData.production = data.production;
        }
        if (data.staff) {
            ranchData.staff = data.staff;
        }
        if (data.storage) {
            ranchData.storage.capacity = data.storage.capacity !== undefined ? data.storage.capacity : ranchData.storage.capacity;
            ranchData.storage.maxCapacity = data.storage.maxCapacity !== undefined ? data.storage.maxCapacity : ranchData.storage.maxCapacity;
            ranchData.storage.items = data.storage.items || ranchData.storage.items;
        }
        if (data.economy) {
            ranchData.economy.updated = data.economy.updated || ranchData.economy.updated;
            ranchData.economy.prices = data.economy.prices || ranchData.economy.prices;
        }
    }

    // -------------------------------------------------------------------------
    // Render Functions
    // -------------------------------------------------------------------------
    function renderAll() {
        renderOverview();
        renderAnimals();
        renderProduction();
        renderStaff();
        renderStorage();
        renderEconomy();
    }

    // -- Overview --
    function renderOverview() {
        var ov = ranchData.overview;
        document.getElementById('stat-animals').textContent = ov.animals;
        document.getElementById('stat-staff').textContent = ov.staff;

        var storagePct = ov.storageMax > 0 ? Math.round((ov.storageUsed / ov.storageMax) * 100) : 0;
        document.getElementById('stat-storage').textContent = storagePct + '%';
        document.getElementById('stat-income').textContent = '$' + formatNumber(ov.dailyIncome);
        document.getElementById('stat-level').textContent = ov.level;
        document.getElementById('stat-reputation').textContent = ov.reputation;
        document.getElementById('overview-status').textContent = ov.status;

        var actList = document.getElementById('overview-activity');
        if (ov.activity && ov.activity.length > 0) {
            actList.innerHTML = '';
            for (var i = 0; i < ov.activity.length; i++) {
                var li = document.createElement('li');
                li.className = 'wl-list__item';
                li.textContent = ov.activity[i];
                actList.appendChild(li);
            }
        } else {
            actList.innerHTML = '<li class="wl-list__item">No recent activity.</li>';
        }
    }

    // -- Animals --
    function renderAnimals() {
        var container = document.getElementById('animals-list');
        var animals = ranchData.animals;

        if (!animals || animals.length === 0) {
            container.innerHTML = '<div class="wl-card wl-card--empty"><p class="wl-card__text">No animals on this ranch yet.</p></div>';
            return;
        }

        var html = '';
        for (var i = 0; i < animals.length; i++) {
            var a = animals[i];
            var healthPct = a.maxHealth > 0 ? Math.round((a.health / a.maxHealth) * 100) : 100;
            html += '<div class="wl-card wl-card--animal">';
            html += '<span class="wl-card__name">' + escapeHtml(a.name || 'Unknown') + '</span>';
            html += '<span class="wl-card__breed">' + escapeHtml(a.breed || a.type || 'Unknown') + '</span>';
            html += '<div class="wl-card__stats">';
            if (a.age !== undefined) html += '<span class="wl-card__stat-pip">Age: ' + a.age + '</span>';
            if (a.gender) html += '<span class="wl-card__stat-pip">' + escapeHtml(a.gender) + '</span>';
            if (a.mood) html += '<span class="wl-card__stat-pip">Mood: ' + escapeHtml(a.mood) + '</span>';
            html += '</div>';
            html += '<div class="wl-card__health-bar"><div class="wl-card__health-fill" style="width:' + healthPct + '%"></div></div>';
            html += '</div>';
        }
        container.innerHTML = html;
    }

    // -- Production --
    function renderProduction() {
        var container = document.getElementById('production-list');
        var prods = ranchData.production;

        if (!prods || prods.length === 0) {
            container.innerHTML = '<div class="wl-card wl-card--empty"><p class="wl-card__text">No active production.</p></div>';
            return;
        }

        var html = '';
        for (var i = 0; i < prods.length; i++) {
            var p = prods[i];
            var pct = p.progress !== undefined ? Math.min(100, Math.max(0, p.progress)) : 0;
            html += '<div class="wl-card wl-card--production">';
            html += '<div class="wl-card__row">';
            html += '<h3 class="wl-card__heading">' + escapeHtml(p.name || 'Production') + '</h3>';
            html += '<span class="wl-card__pct">' + Math.round(pct) + '%</span>';
            html += '</div>';
            html += '<div class="wl-progress"><div class="wl-progress__bar" style="width:' + pct + '%"></div></div>';
            if (p.output) html += '<p class="wl-card__text">Output: ' + escapeHtml(p.output) + '</p>';
            if (p.timeLeft) html += '<p class="wl-card__text">Time remaining: ' + escapeHtml(p.timeLeft) + '</p>';
            html += '</div>';
        }
        container.innerHTML = html;
    }

    // -- Staff --
    function renderStaff() {
        var container = document.getElementById('staff-list');
        var staff = ranchData.staff;

        if (!staff || staff.length === 0) {
            container.innerHTML = '<div class="wl-card wl-card--empty"><p class="wl-card__text">No staff employed.</p></div>';
            return;
        }

        var html = '';
        for (var i = 0; i < staff.length; i++) {
            var s = staff[i];
            var badgeClass = getBadgeClass(s.role);
            html += '<div class="wl-card wl-card--staff">';
            html += '<span class="wl-card__name">' + escapeHtml(s.name || 'Unknown') + '</span>';
            html += '<span class="wl-badge ' + badgeClass + '">' + escapeHtml(s.role || 'Worker') + '</span>';
            if (s.wage !== undefined) html += '<span class="wl-card__wage">Wage: $' + formatNumber(s.wage) + '/day</span>';
            html += '</div>';
        }
        container.innerHTML = html;
    }

    function getBadgeClass(role) {
        if (!role) return 'wl-badge--default';
        var r = role.toLowerCase();
        if (r === 'foreman' || r === 'manager') return 'wl-badge--foreman';
        if (r === 'rancher' || r === 'herder') return 'wl-badge--rancher';
        if (r === 'farmhand' || r === 'laborer') return 'wl-badge--farmhand';
        if (r === 'veterinarian' || r === 'vet') return 'wl-badge--veterinarian';
        return 'wl-badge--default';
    }

    // -- Storage --
    function renderStorage() {
        var container = document.getElementById('storage-grid');
        var stor = ranchData.storage;
        var cap = stor.capacity || 0;
        var maxCap = stor.maxCapacity || 0;
        var capPct = maxCap > 0 ? Math.round((cap / maxCap) * 100) : 0;

        var capBar = document.getElementById('storage-capacity-bar');
        var capText = document.getElementById('storage-capacity-text');
        if (capBar) capBar.style.width = capPct + '%';
        if (capText) capText.textContent = cap + ' / ' + maxCap + ' slots used';

        var items = stor.items;
        if (!items || items.length === 0) {
            container.innerHTML = '<div class="wl-card wl-card--empty"><p class="wl-card__text">Storage is empty.</p></div>';
            return;
        }

        var html = '';
        for (var i = 0; i < items.length; i++) {
            var item = items[i];
            var isEmpty = !item.name || item.quantity === 0;
            html += '<div class="wl-slot' + (isEmpty ? ' wl-slot--empty' : '') + '">';
            html += '<span class="wl-slot__name">' + escapeHtml(item.name || 'Empty') + '</span>';
            html += '<span class="wl-slot__qty">' + (isEmpty ? '--' : 'x' + item.quantity) + '</span>';
            html += '</div>';
        }
        container.innerHTML = html;
    }

    // -- Economy --
    function renderEconomy() {
        var container = document.getElementById('economy-prices');
        var econ = ranchData.economy;

        document.getElementById('economy-updated').textContent = 'Last updated: ' + (econ.updated || '--');

        var prices = econ.prices;
        if (!prices || prices.length === 0) {
            container.innerHTML = '<div class="wl-card wl-card--empty"><p class="wl-card__text">No market data available.</p></div>';
            return;
        }

        var html = '';
        for (var i = 0; i < prices.length; i++) {
            var p = prices[i];
            var trendClass = 'wl-card__trend--stable';
            var trendText = 'Stable';
            if (p.trend === 'up') { trendClass = 'wl-card__trend--up'; trendText = '+ Rising'; }
            else if (p.trend === 'down') { trendClass = 'wl-card__trend--down'; trendText = '- Falling'; }

            html += '<div class="wl-card wl-card--price">';
            html += '<span class="wl-card__item">' + escapeHtml(p.item || 'Unknown') + '</span>';
            html += '<span class="wl-card__price">$' + formatNumber(p.price || 0) + '</span>';
            html += '<span class="wl-card__trend ' + trendClass + '">' + trendText + '</span>';
            html += '</div>';
        }
        container.innerHTML = html;
    }

    // -------------------------------------------------------------------------
    // Utility
    // -------------------------------------------------------------------------
    function escapeHtml(str) {
        var div = document.createElement('div');
        div.appendChild(document.createTextNode(str));
        return div.innerHTML;
    }

    function formatNumber(num) {
        var n = parseFloat(num);
        if (isNaN(n)) return '0.00';
        return n.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
    }

    // -------------------------------------------------------------------------
    // NUI Message Handler
    // -------------------------------------------------------------------------
    window.addEventListener('message', function (event) {
        var data = event.data;
        if (!data || !data.action) return;

        switch (data.action) {
            case 'open':
                openUI(data.data || null);
                break;

            case 'close':
                closeUI();
                break;

            case 'update':
                updateRanchData(data.data || null);
                renderAll();
                break;

            case 'updateOverview':
                if (data.data) {
                    ranchData.overview = Object.assign(ranchData.overview, data.data);
                    renderOverview();
                }
                break;

            case 'updateAnimals':
                if (data.data) {
                    ranchData.animals = data.data;
                    renderAnimals();
                }
                break;

            case 'updateProduction':
                if (data.data) {
                    ranchData.production = data.data;
                    renderProduction();
                }
                break;

            case 'updateStaff':
                if (data.data) {
                    ranchData.staff = data.data;
                    renderStaff();
                }
                break;

            case 'updateStorage':
                if (data.data) {
                    ranchData.storage = Object.assign(ranchData.storage, data.data);
                    renderStorage();
                }
                break;

            case 'updateEconomy':
                if (data.data) {
                    ranchData.economy = Object.assign(ranchData.economy, data.data);
                    renderEconomy();
                }
                break;
        }
    });

})();
