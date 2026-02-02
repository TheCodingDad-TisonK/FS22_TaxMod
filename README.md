# FS22 Tax Mod
![Downloads](https://img.shields.io/github/downloads/TheCodingDad-TisonK/FS22_TaxMod/total?style=for-the-badge)
![Release](https://img.shields.io/github/v/release/TheCodingDad-TisonK/FS22_TaxMod?style=for-the-badge)
![License](https://img.shields.io/badge/license-All%20Rights%20Reserved-red?style=for-the-badge)

Daily tax deductions with monthly returns for Farming Simulator 22.

---

## 📌 Overview

The **FS22 Tax Mod** applies a daily tax deduction based on your farm’s balance and returns a percentage of the taxes paid at the end of each month. It is designed to add realism and challenge to your gameplay by simulating taxation and monthly refunds.

Original mod page: https://www.kingmods.net/en/fs22/mods/73694/tax-mod

---

## 🧾 Features

- 💸 **Daily tax deduction** based on your farm balance  
- 🔁 **Monthly tax return** based on percentage of taxes paid  
- ⚙️ **Configurable tax rates:** low, medium, high  
- 🧮 **Minimum balance** required before taxes apply  
- 🔔 Optional **in-game notifications**
- 📊 Optional **tax statistics display**
- 🐞 **Debug mode** for testing and logging
- ✅ Works in **singleplayer & multiplayer** (server side only)

---

## 🛠️ Default Configuration

| Setting | Default | Description |
|--------|---------|-------------|
| enabled | `true` | Enable/disable the tax system |
| taxRate | `medium` | Tax rate (low / medium / high) |
| returnPercentage | `20` | Monthly return percentage |
| minimumBalance | `1000` | Minimum balance before taxes apply |
| showNotification | `true` | Show notifications in-game |
| showStatistics | `true` | Print stats in console |
| debugMode | `true` | Enable debug logging |

Tax rates:

- **low:** 1%  
- **medium:** 2%  
- **high:** 3%

---

## 🚀 Installation

1. Download the mod `.zip` file.  
2. Place it into:

Documents/My Games/Farming Simulator 22/mods
3. Enable the mod in the Mod Manager before loading your save.

---

## 🎮 How It Works

- Every day the mod checks your farm balance.
- If balance is above the minimum, it deducts the daily tax.
- At the end of each month, it returns a percentage of the taxes paid.

---

## 🧠 Console Commands

Open the console (usually `~` or `F1`) and type:

### Basic Commands

| Command | Description |
|--------|-------------|
| `tax` | Show help |
| `tax status` | Display current settings and stats |
| `tax enable` | Enable tax system |
| `tax disable` | Disable tax system |
| `tax reload` | Reload settings from XML |

### Settings

| Command | Example | Description |
|--------|---------|-------------|
| `tax rate [low/medium/high]` | `tax rate high` | Set tax rate |
| `tax return [0-100]` | `tax return 30` | Set monthly return percentage |
| `tax minimum [amount]` | `tax minimum 2000` | Set minimum balance |

### Extra

| Command | Description |
|--------|-------------|
| `tax statistics` | Print tax statistics |
| `tax info` | Show info notification in-game |
| `tax debug` | Toggle debug mode |
| `tax simulate` | Simulate daily tax (for testing) |

---

## 📊 Tax Statistics

The mod tracks:

- Total taxes paid  
- Total tax returns  
- Taxes paid this month  
- Days taxed  
- Months returned  
- Average daily tax  

---

## ⚖️ License

All rights reserved. Unauthorized redistribution, copying, or claiming this mod as your own is **strictly prohibited**.  
Original author: **TisonK** 

---

## 📬 Support

Report bugs or request help in the comments section of the original mod page.

---

*Enjoy your farming experience!* 🌾
