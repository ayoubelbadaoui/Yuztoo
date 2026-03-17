<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Vos clients - Yuztoo</title>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600&display=swap" rel="stylesheet">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Outfit', system-ui, sans-serif;
            background: #f5f5f5;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }

        .phone-frame {
            width: 390px;
            height: 884px;
            background: #0E2A44;
            border: 14px solid #1a1a1a;
            border-radius: 48px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            display: flex;
            flex-direction: column;
            overflow: hidden;
            position: relative;
        }

        .status-bar {
            height: 47px;
            background: #0B1F33;
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 0 30px;
            font-size: 13px;
            color: white;
            font-weight: 500;
            border-bottom: 1px solid rgba(212, 175, 55, 0.1);
        }

        .header {
            padding: 16px 24px;
            background: #0B1F33;
            display: flex;
            align-items: center;
            gap: 12px;
            border-bottom: 1px solid rgba(212, 175, 55, 0.1);
        }

        .header-icon {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            border: 2px solid #D4A017;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .header h1 {
            font-size: 20px;
            font-weight: 600;
            color: white;
            margin: 0;
        }

        .content {
            flex: 1;
            overflow-y: auto;
            padding-bottom: 80px;
        }

        .search-section {
            padding: 16px 24px;
            display: flex;
            align-items: center;
            gap: 12px;
            border-bottom: 1px solid rgba(212, 175, 55, 0.1);
        }

        .mode-pro-badge {
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 4px;
            color: #D4A017;
            font-size: 11px;
            font-weight: 600;
            text-align: center;
        }

        .mode-pro-icon {
            width: 32px;
            height: 32px;
            border-radius: 50%;
            border: 2px solid #D4A017;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 16px;
        }

        .search-input {
            flex: 1;
            padding: 12px 16px;
            background: white;
            border: none;
            border-radius: 20px;
            font-size: 14px;
            color: #999;
            outline: none;
        }

        .search-icon {
            width: 32px;
            height: 32px;
            background: none;
            border: none;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #D4A017;
        }

        .filter-btn {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            border: 2px solid #D4A017;
            background: none;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #D4A017;
            transition: all 0.3s;
        }

        .filter-btn:hover {
            background: rgba(212, 175, 55, 0.1);
        }

        .client-item {
            padding: 24px;
            border-bottom: 1px solid rgba(212, 175, 55, 0.1);
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .client-left {
            display: flex;
            align-items: center;
            gap: 12px;
            flex: 1;
        }

        .client-avatar {
            width: 56px;
            height: 56px;
            border-radius: 50%;
            border: 2px solid #D4A017;
            background: #1A2B4D;
            display: flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
            font-size: 24px;
        }

        .client-info h3 {
            font-size: 15px;
            font-weight: 600;
            color: white;
            margin: 0;
        }

        .client-info p {
            font-size: 12px;
            color: #999;
            margin: 2px 0 0 0;
        }

        .client-action {
            width: 36px;
            height: 36px;
            border-radius: 50%;
            border: 2px solid #D4A017;
            background: none;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #D4A017;
            transition: all 0.3s;
            flex-shrink: 0;
        }

        .client-action:hover {
            background: rgba(212, 175, 55, 0.1);
        }

        .info-box {
            margin: 24px;
            padding: 20px;
            background: transparent;
            border: 1px solid #D4A017;
            border-radius: 16px;
            text-align: center;
            color: #ccc;
            font-size: 13px;
            line-height: 1.6;
        }

        .info-box .gold-text {
            color: #D4A017;
            font-weight: 600;
        }

        .qr-box {
            margin: 24px;
            padding: 32px 24px;
            background: transparent;
            border: 1px solid #D4A017;
            border-radius: 16px;
            text-align: center;
        }

        .qr-icon {
            width: 40px;
            height: 40px;
            border: 2px solid #D4A017;
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 16px;
            color: #D4A017;
        }

        .qr-code {
            width: 120px;
            height: 120px;
            background: white;
            border-radius: 8px;
            margin: 16px auto;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 80px;
        }

        .qr-text {
            color: #ccc;
            font-size: 13px;
            line-height: 1.6;
        }

        .bottom-nav {
            position: absolute;
            bottom: 0;
            left: 0;
            right: 0;
            height: 80px;
            background: #0B1F33;
            border-top: 1px solid rgba(212, 175, 55, 0.2);
            display: flex;
            justify-content: space-around;
            align-items: center;
            padding-bottom: 8px;
        }

        .nav-btn {
            background: none;
            border: none;
            cursor: pointer;
            width: 40px;
            height: 40px;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: transform 0.3s;
            color: #D4A017;
            font-size: 24px;
        }

        .nav-btn:hover {
            transform: scale(1.15);
        }

        .home-indicator {
            position: absolute;
            bottom: 8px;
            left: 50%;
            transform: translateX(-50%);
            width: 120px;
            height: 5px;
            background: rgba(0, 0, 0, 0.2);
            border-radius: 3px;
            z-index: 50;
        }
    </style>
</head>
<body>
    <div class="phone-frame">
        <!-- Status Bar -->
        <div class="status-bar">
            <span>9:41</span>
            <span>●  ◆  ⚡</span>
        </div>

        <!-- Header -->
        <div class="header">
            <div class="header-icon">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#D4A017" stroke-width="2">
                    <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                    <circle cx="12" cy="7" r="4"/>
                </svg>
            </div>
            <h1>Vos clients</h1>
        </div>

        <!-- Content -->
        <div class="content">
            <!-- Search Section -->
            <div class="search-section">
                <div class="mode-pro-badge">
                    <div class="mode-pro-icon">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                            <circle cx="12" cy="7" r="4"/>
                        </svg>
                    </div>
                    <span>Mode Pro</span>
                </div>
                <input type="text" class="search-input" placeholder="Rechercher">
                <button class="filter-btn">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
                    </svg>
                </button>
            </div>

            <!-- Client Item -->
            <div class="client-item">
                <div class="client-left">
                    <div class="client-avatar">👤</div>
                    <div class="client-info">
                        <h3>M Guyomar Pascal</h3>
                        <p>Conseiller Yuztoo pour bien démarrer</p>
                    </div>
                </div>
                <button class="client-action">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M5 12h14M12 5l7 7-7 7"/>
                    </svg>
                </button>
            </div>

            <!-- Info Box -->
            <div class="info-box">
                Vos clients vous appartiennent désormais. <span class="gold-text">Yuztoo</span> vous aide à les garder
            </div>

            <!-- QR Box -->
            <div class="qr-box">
                <div class="qr-icon">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <rect x="3" y="3" width="18" height="18" rx="2" ry="2"/>
                        <rect x="7" y="7" width="10" height="10"/>
                        <circle cx="9" cy="9" r="1"/>
                    </svg>
                </div>
                <div class="qr-code">⬜</div>
                <div class="qr-text">
                    Faites scanez ce QR code<br>pour ajouter un client
                </div>
            </div>
        </div>

        <!-- Bottom Navigation -->
        <div class="bottom-nav">
            <button class="nav-btn">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
                    <circle cx="9" cy="7" r="4"/>
                    <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
                    <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
                </svg>
            </button>
            <button class="nav-btn">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="8" y1="6" x2="21" y2="6"/>
                    <line x1="8" y1="12" x2="21" y2="12"/>
                    <line x1="8" y1="18" x2="21" y2="18"/>
                    <line x1="3" y1="6" x2="3.01" y2="6"/>
                    <line x1="3" y1="12" x2="3.01" y2="12"/>
                    <line x1="3" y1="18" x2="3.01" y2="18"/>
                </svg>
            </button>
            <button class="nav-btn">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <rect x="6" y="9" width="12" height="13" rx="2" ry="2"/>
                    <path d="M9 5a3 3 0 0 1 6 0"/>
                </svg>
            </button>
            <button class="nav-btn">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"/>
                </svg>
            </button>
            <button class="nav-btn">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="12" cy="12" r="1"/>
                    <circle cx="19" cy="12" r="1"/>
                    <circle cx="5" cy="12" r="1"/>
                    <circle cx="12" cy="19" r="1"/>
                    <circle cx="12" cy="5" r="1"/>
                    <circle cx="17.66" cy="17.66" r="1"/>
                    <circle cx="6.34" cy="6.34" r="1"/>
                    <circle cx="17.66" cy="6.34" r="1"/>
                    <circle cx="6.34" cy="17.66" r="1"/>
                </svg>
            </button>
        </div>

        <!-- Home Indicator --> 
        <div class="home-indicator"></div>
    </div>
</body>
</html>