$(document).ready(function() {
    let currentData = {
        stock: [],
        catalog: [],
        orders: [],
        societyMoney: 0,
        isBoss: false,
        currentCategory: null
    };

    // Listen for messages from Lua
    window.addEventListener('message', function(event) {
        const data = event.data;

        switch(data.type) {
            case 'openUI':
                openUI(data);
                break;
            case 'closeUI':
                closeUI();
                break;
            case 'updateSocietyMoney':
                updateSocietyMoney(data.money);
                break;
        }
    });

    // Open UI
    function openUI(data) {
        currentData.stock = data.stock || [];
        currentData.catalog = data.catalog || [];
        currentData.orders = data.orders || [];
        currentData.societyMoney = data.societyMoney || 0;
        currentData.isBoss = data.isBoss || false;

        updateSocietyMoney(currentData.societyMoney);

        // Show/hide boss button
        if (currentData.isBoss) {
            $('#bossBtn').show();
        } else {
            $('#bossBtn').hide();
        }

        // Show main menu
        showView('mainMenu');
        $('#app').fadeIn(300);
    }

    // Close UI
    function closeUI() {
        $('#app').fadeOut(300);
        $.post('http://zcon/closeUI', JSON.stringify({}));
    }

    // Update society money display
    function updateSocietyMoney(money) {
        currentData.societyMoney = money;
        $('#societyMoney').text(formatNumber(money));
        $('#bossSocietyMoney').text(formatNumber(money));
    }

    // Show specific view
    function showView(viewId) {
        $('.view').hide();
        $('#' + viewId).show();

        // Load data for the view
        switch(viewId) {
            case 'stockView':
                loadStock();
                break;
            case 'catalogView':
                loadCatalog();
                break;
            case 'ordersView':
                loadOrders();
                break;
        }
    }

    // Load stock
    function loadStock() {
        const container = $('#stockList');
        container.empty();

        if (currentData.stock.length === 0) {
            container.html(`
                <div class="empty-state">
                    <i class="fas fa-box-open"></i>
                    <p>Aucun véhicule en stock</p>
                </div>
            `);
            return;
        }

        currentData.stock.forEach(item => {
            container.append(`
                <div class="item-card">
                    <div class="item-header">
                        <div class="item-title">${item.vehicle_name}</div>
                        <div class="item-badge">x${item.quantity}</div>
                    </div>
                    <div class="item-details">
                        <div class="item-detail">
                            <i class="fas fa-dollar-sign"></i>
                            <span>Achat: $${formatNumber(item.buy_price)}</span>
                        </div>
                        <div class="item-detail">
                            <i class="fas fa-tag"></i>
                            <span>Vente: $${formatNumber(item.sell_price)}</span>
                        </div>
                    </div>
                </div>
            `);
        });
    }

    // Load catalog
    function loadCatalog() {
        const container = $('#catalogList');
        container.empty();

        if (currentData.catalog.length === 0) {
            container.html(`
                <div class="empty-state">
                    <i class="fas fa-folder-open"></i>
                    <p>Aucun catalogue disponible</p>
                </div>
            `);
            return;
        }

        currentData.catalog.forEach(category => {
            const card = $(`
                <div class="category-card" data-category="${category.category}">
                    <div class="category-info">
                        <h3>${category.category}</h3>
                        <p>${category.vehicles.length} véhicules disponibles</p>
                    </div>
                    <div class="category-arrow">
                        <i class="fas fa-chevron-right"></i>
                    </div>
                </div>
            `);

            card.click(function() {
                openCategory(category);
            });

            container.append(card);
        });
    }

    // Open category
    function openCategory(category) {
        currentData.currentCategory = category;
        $('#categoryTitle').html(`<i class="fas fa-car"></i> ${category.category}`);

        const container = $('#vehicleList');
        container.empty();

        category.vehicles.forEach(vehicle => {
            const card = $(`
                <div class="item-card">
                    <div class="item-header">
                        <div class="item-title">${vehicle.name}</div>
                        <div class="item-badge">$${formatNumber(vehicle.price)}</div>
                    </div>
                    <div class="item-actions">
                        <button class="item-btn" data-model="${vehicle.model}" data-name="${vehicle.name}" data-price="${vehicle.price}">
                            <i class="fas fa-shopping-cart"></i>
                            <span>Commander</span>
                        </button>
                    </div>
                </div>
            `);

            card.find('.item-btn').click(function() {
                const model = $(this).data('model');
                const name = $(this).data('name');
                const price = $(this).data('price');
                orderVehicle(model, name, price);
            });

            container.append(card);
        });

        showView('categoryView');
    }

    // Order vehicle
    function orderVehicle(model, name, price) {
        showInputModal('Commander ' + name, 'Quantité (1-10)', function(quantity) {
            quantity = parseInt(quantity);

            if (!quantity || quantity < 1 || quantity > 10) {
                return;
            }

            const totalPrice = price * quantity;

            showConfirmModal(
                'Confirmer la commande',
                `Commander ${quantity}x ${name} pour $${formatNumber(totalPrice)}?`,
                function(confirmed) {
                    if (confirmed) {
                        $.post('http://zcon/placeOrder', JSON.stringify({
                            model: model,
                            name: name,
                            quantity: quantity,
                            totalPrice: totalPrice
                        }));

                        closeUI();
                    }
                }
            );
        });
    }

    // Load orders
    function loadOrders() {
        const container = $('#ordersList');
        container.empty();

        if (currentData.orders.length === 0) {
            container.html(`
                <div class="empty-state">
                    <i class="fas fa-inbox"></i>
                    <p>Aucune commande en cours</p>
                </div>
            `);
            return;
        }

        currentData.orders.forEach(order => {
            const statusClass = order.status === 'pending' ? 'pending' : 'in-progress';
            const statusText = order.status === 'pending' ? 'En attente' : 'En livraison';
            const canStart = order.status === 'pending';

            const card = $(`
                <div class="item-card">
                    <div class="item-header">
                        <div class="item-title">${order.quantity}x ${order.vehicle_name}</div>
                        <div class="item-badge ${statusClass}">${statusText}</div>
                    </div>
                    <div class="item-details">
                        <div class="item-detail">
                            <i class="fas fa-dollar-sign"></i>
                            <span>$${formatNumber(order.total_price)}</span>
                        </div>
                    </div>
                    <div class="item-actions">
                        <button class="item-btn ${!canStart ? 'secondary' : ''}" data-order-id="${order.id}" ${!canStart ? 'disabled' : ''}>
                            <i class="fas fa-truck"></i>
                            <span>${canStart ? 'Aller chercher' : 'En cours...'}</span>
                        </button>
                    </div>
                </div>
            `);

            if (canStart) {
                card.find('.item-btn').click(function() {
                    const orderId = $(this).data('order-id');
                    $.post('http://zcon/startDelivery', JSON.stringify({ orderId: orderId }));
                    closeUI();
                });
            }

            container.append(card);
        });
    }

    // Show input modal
    function showInputModal(title, description, callback) {
        $('#modalTitle').text(title);
        $('#modalDescription').text(description);
        $('#modalInput').val('');
        $('#inputModal').fadeIn(200);

        $('#modalConfirm').off('click').on('click', function() {
            const value = $('#modalInput').val();
            $('#inputModal').fadeOut(200);
            if (callback && value) {
                callback(value);
            }
        });
    }

    // Show confirm modal
    function showConfirmModal(title, description, callback) {
        $('#confirmTitle').text(title);
        $('#confirmDescription').text(description);
        $('#confirmModal').fadeIn(200);

        $('#confirmConfirm').off('click').on('click', function() {
            $('#confirmModal').fadeOut(200);
            if (callback) {
                callback(true);
            }
        });

        $('#confirmCancel, #confirmClose').off('click').on('click', function() {
            $('#confirmModal').fadeOut(200);
            if (callback) {
                callback(false);
            }
        });
    }

    // Format number with commas
    function formatNumber(num) {
        return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    }

    // Close button
    $('#closeBtn').click(function() {
        closeUI();
    });

    // Main menu buttons
    $('#stockBtn').click(function() {
        showView('stockView');
    });

    $('#catalogBtn').click(function() {
        showView('catalogView');
    });

    $('#ordersBtn').click(function() {
        showView('ordersView');
    });

    $('#bossBtn').click(function() {
        showView('bossView');
    });

    // Back buttons
    $('.back-btn').click(function() {
        const backTo = $(this).data('back');
        showView(backTo);
    });

    // Boss actions
    $('#withdrawBtn').click(function() {
        showInputModal('Retirer argent', `Disponible: $${formatNumber(currentData.societyMoney)}`, function(amount) {
            amount = parseInt(amount);
            if (!amount || amount <= 0) {
                return;
            }

            $.post('http://zcon/withdrawMoney', JSON.stringify({ amount: amount }));
        });
    });

    $('#depositBtn').click(function() {
        showInputModal('Déposer argent', 'Montant à déposer', function(amount) {
            amount = parseInt(amount);
            if (!amount || amount <= 0) {
                return;
            }

            $.post('http://zcon/depositMoney', JSON.stringify({ amount: amount }));
        });
    });

    // Modal close
    $('#modalClose, #modalCancel').click(function() {
        $('#inputModal').fadeOut(200);
    });

    // ESC key to close
    $(document).keyup(function(e) {
        if (e.key === "Escape") {
            if ($('#confirmModal').is(':visible')) {
                $('#confirmModal').fadeOut(200);
            } else if ($('#inputModal').is(':visible')) {
                $('#inputModal').fadeOut(200);
            } else if ($('#app').is(':visible')) {
                closeUI();
            }
        }
    });
});
