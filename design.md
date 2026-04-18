<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Recommandations - Yuztoo</title>
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
            background: #0B162C;
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
            background: #0B162C;
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
            background: #0B162C;
            border-bottom: 1px solid rgba(212, 175, 55, 0.3);
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .header-icon {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            border: 2px solid #D4A017;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #D4A017;
        }

        .header h1 {
            font-size: 18px;
            font-weight: 600;
            color: white;
            margin: 0;
        }

        .content {
            flex: 1;
            overflow-y: auto;
            padding-bottom: 80px;
        }

        .description {
            padding: 20px 24px;
            text-align: center;
            color: #ccc;
            font-size: 13px;
            line-height: 1.5;
            border-bottom: 1px solid rgba(212, 175, 55, 0.1);
        }

        .featured-card {
            margin: 20px 24px;
            position: relative;
            border-radius: 12px;
            overflow: hidden;
            height: 140px;
        }

        .featured-image {
            width: 100%;
            height: 100%;
            background: linear-gradient(135deg, #D4A017 0%, #E8D5B7 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            color: #999;
            font-size: 14px;
            position: relative;
        }

        .featured-heart {
            position: absolute;
            top: 12px;
            right: 12px;
            width: 40px;
            height: 40px;
            border-radius: 50%;
            background: white;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 20px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }

        .search-section {
            padding: 16px 24px;
        }

        .search-input {
            width: 100%;
            padding: 12px 16px;
            background: white;
            border: none;
            border-radius: 20px;
            font-size: 13px;
            color: #999;
            outline: none;
            font-family: 'Outfit', sans-serif;
        }

        .search-input::placeholder {
            color: #D4A017;
        }

        .business-grid {
            padding: 0 24px 24px;
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 12px;
        }

        .business-card {
            position: relative;
            border-radius: 8px;
            overflow: hidden;
            height: 120px;
            cursor: pointer;
            transition: all 0.3s;
        }

        .business-card:hover {
            transform: scale(1.05);
        }

        .business-image {
            width: 100%;
            height: 100%;
            background: linear-gradient(135deg, #D4A017 0%, #E8D5B7 100%);
            display: flex;
            align-items: flex-end;
            justify-content: center;
            padding-bottom: 8px;
            position: relative;
        }

        .business-name {
            font-size: 11px;
            color: white;
            font-weight: 500;
            text-align: center;
            max-width: 100%;
            line-height: 1.2;
            text-shadow: 0 1px 3px rgba(0,0,0,0.3);
        }

        .invite-btn {
            margin: 0 24px 24px;
            width: calc(100% - 48px);
            padding: 14px;
            background: #D4A017;
            color: white;
            border: none;
            border-radius: 24px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
            font-family: 'Outfit', sans-serif;
        }

        .invite-btn:hover {
            background: #C09010;
            transform: scale(1.02);
        }

        .invite-btn:active {
            transform: scale(0.98);
        }

        .bottom-nav {
            position: absolute;
            bottom: 0;
            left: 0;
            right: 0;
            height: 80px;
            background: #0B162C;
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
        }

        .nav-btn:hover {
            transform: scale(1.15);
        }

        .nav-btn svg {
            width: 24px;
            height: 24px;
            stroke: #D4A017;
            fill: none;
            stroke-width: 2;
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
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                    <circle cx="12" cy="7" r="4"/>
                </svg>
            </div>
            <h1>Recommandations</h1>
        </div>

        <!-- Content -->
        <div class="content">
            <!-- Description -->
            <div class="description">
                Des commerces recommandés par ceux que tu fréquentes déjà.
            </div>

            <!-- Featured Card -->
            <div class="featured-card">
                <div class="featured-image">
                    Image Commerces
                    <div class="featured-heart">
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="#D4A017" stroke="none">
                            <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
                        </svg>
                    </div>
                </div>
            </div>

            <!-- Search Section -->
            <div class="search-section">
                <input type="text" class="search-input" placeholder="Boulanger">
            </div>

            <!-- Business Grid -->
            <div class="business-grid">
                <div class="business-card">
                    <div class="business-image">
                        <div class="business-name">Boulangerie Bon fournil</div>
                    </div>
                </div>

                <div class="business-card">
                    <div class="business-image">
                        <div class="business-name">Boulangerie Tampis</div>
                    </div>
                </div>

                <div class="business-card">
                    <div class="business-image">
                        <div class="business-name">Pâtisserie Laurent</div>
                    </div>
                </div>
            </div>

            <!-- Invite Button -->
            <button class="invite-btn">Invite un commerçant</button>
        </div>

        <!-- Bottom Navigation -->
        <div class="bottom-nav">
            <button class="nav-btn">
                <svg viewBox="0 0 24 24">
                    <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
                </svg>
            </button>
            <button class="nav-btn">
                <svg viewBox="0 0 24 24">
                    <path d="M4 19V5a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2z"/>
                    <polyline points="12 2 12 8"/>
                    <polyline points="12 16 12 22"/>
                </svg>
            </button>
            <button class="nav-btn">
                <svg viewBox="0 0 24 24">
                    <rect x="3" y="3" width="18" height="18" rx="2" ry="2"/>
                    <circle cx="8.5" cy="8.5" r="1.5"/>
                    <polyline points="21 15 16 10 5 21"/>
                </svg>
            </button>
            <button class="nav-btn">
                <svg viewBox="0 0 24 24">
                    <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
                    <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
                </svg>
            </button>
            <button class="nav-btn">
                <svg viewBox="0 0 24 24">
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