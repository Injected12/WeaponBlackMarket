$(function() {
    let currentWeapons = [];
    
    // Listen for messages from the client script
    window.addEventListener('message', function(event) {
        const data = event.data;
        
        switch (data.type) {
            case 'openMarket':
                $('#container').fadeIn(200);
                $('#login-screen').show();
                $('#weapons-menu').hide();
                // Clear previous inputs
                $('#username').val('');
                $('#password').val('');
                $('#login-error').text('');
                break;
                
            case 'closeMarket':
                $('#container').fadeOut(200);
                break;
                
            case 'loadWeapons':
                // Save weapons data and show weapons menu
                currentWeapons = data.weapons;
                displayWeapons();
                $('#login-screen').hide();
                $('#weapons-menu').show();
                break;
                
            case 'purchaseError':
                showMessage(data.message, 'error');
                break;
        }
    });
    
    // Handle login button click
    $('#login-btn').on('click', function() {
        const username = $('#username').val().trim();
        const password = $('#password').val().trim();
        
        if (username === '' || password === '') {
            $('#login-error').text('Please enter both username and password');
            return;
        }
        
        // Send login request to client script
        $.post('https://privateWeapons/login', JSON.stringify({
            username: username,
            password: password
        }), function(response) {
            if (!response.success) {
                $('#login-error').text(response.message || 'Login failed');
            }
        });
    });
    
    // Handle logout button click
    $('#logout-btn').on('click', function() {
        $.post('https://privateWeapons/closeUI', JSON.stringify({}));
    });
    
    // Function to display weapons in the menu
    function displayWeapons() {
        const weaponsList = $('#weapons-list');
        weaponsList.empty();
        
        currentWeapons.forEach(weapon => {
            const weaponElement = $(`
                <div class="weapon-item" data-weapon="${weapon.name}">
                    <div class="weapon-name">${weapon.label}</div>
                    <div class="weapon-price">$${weapon.price}</div>
                </div>
            `);
            
            weaponsList.append(weaponElement);
        });
        
        // Add click event to weapon items
        $('.weapon-item').on('click', function() {
            const weaponName = $(this).data('weapon');
            purchaseWeapon(weaponName);
        });
    }
    
    // Function to purchase a weapon
    function purchaseWeapon(weaponName) {
        $.post('https://privateWeapons/purchaseWeapon', JSON.stringify({
            weapon: weaponName
        }), function(response) {
            if (!response.success) {
                showMessage(response.message || 'Purchase failed', 'error');
            }
        });
    }
    
    // Function to show messages in the weapons menu
    function showMessage(message, type) {
        const messageContainer = $('#purchase-message');
        messageContainer.removeClass('error success');
        messageContainer.addClass(type);
        messageContainer.text(message);
        messageContainer.fadeIn(200);
        
        // Hide message after 3 seconds
        setTimeout(() => {
            messageContainer.fadeOut(200);
        }, 3000);
    }
    
    // Handle keydown for ESC key
    $(document).keydown(function(e) {
        if (e.keyCode === 27) { // ESC key
            $.post('https://privateWeapons/closeUI', JSON.stringify({}));
        }
    });
});
