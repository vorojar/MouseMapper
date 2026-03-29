[English](README.md) | [简体中文](README_zh-CN.md) | [繁體中文](README_zh-TW.md) | [日本語](README_ja.md) | [한국어](README_ko.md) | [Français](README_fr.md)

# MouseMapper

**Associez les boutons latéraux de votre souris à n'importe quelle touche clavier.** Compatible macOS et Windows.

## Pourquoi ce projet

Si vous utilisez une souris multi-boutons Logitech ou d'une autre marque, vous avez sûrement rencontré ces frustrations :

**Les limites de Logitech Options+ :**
- Les boutons latéraux ne peuvent être associés qu'à des actions navigateur (précédent/suivant) — **impossible de les mapper sur une touche clavier arbitraire**
- Utiliser un bouton latéral comme fn / Command / Alt seul ? Impossible
- Mapper une combinaison comme `Ctrl+C` ? Non pris en charge
- Le logiciel fait plus de 500 Mo, se lance au démarrage, consomme de la mémoire, et vous harcèle de connexions, synchronisations et mises à jour
- Sur macOS, conflits fréquents avec le système, mappings perdus après mise à jour

**Les alternatives :** Soit payantes (BetterTouchTool), soit complexes à configurer (Karabiner), soit limitées à une seule plateforme.

**C'est pourquoi j'ai créé MouseMapper :**
- Un seul exe / un seul binaire, double-clic pour lancer, zéro dépendance
- Mapping vers n'importe quelle touche clavier, y compris les modificateurs seuls (fn, Command/Win, Alt/Option, Shift, Ctrl)
- Combinaisons de touches supportées (`ctrl+c`, `shift+alt`, `command+space`, etc.)
- Fichier de configuration JSON, clair et lisible, modifiez puis redémarrez pour appliquer
- Programme entier de moins de 500 Ko — pas de réseau, pas de connexion, pas de mises à jour, pas de tracas

## Téléchargement

**Windows :** [Télécharger MouseMapper.exe](https://github.com/vorojar/MouseMapper/releases) — Double-clic pour lancer, icône système automatique, démarrage automatique.

**macOS :** Compilation depuis les sources (voir ci-dessous).

## Démarrage rapide

### Windows

1. Téléchargez `MouseMapper.exe`
2. Double-clic pour lancer → génère automatiquement `config.json` dans le répertoire de l'exe → configure automatiquement le démarrage
3. Modifiez `config.json` pour changer les mappings, redémarrez le programme pour appliquer
4. Clic droit sur l'icône dans la zone de notification → gérer le démarrage / quitter

### macOS

```bash
git clone https://github.com/vorojar/MouseMapper.git
cd MouseMapper
bash install.sh
```

Au premier lancement, une autorisation est nécessaire : `Réglages du système → Confidentialité et sécurité → Accessibilité`.

## Configuration

Les deux plateformes partagent le même format `config.json` :

```json
{
  "mappings": [
    {
      "button": 3,
      "key": "return",
      "action": "click"
    },
    {
      "button": 4,
      "key": "alt",
      "action": "hold"
    }
  ]
}
```

| Champ | Description |
|-------|-------------|
| `button` | Numéro du bouton souris : `2`=milieu, `3`=latéral arrière, `4`=latéral avant |
| `key` | Touche cible, combinaisons avec `+` : `return`, `ctrl+c`, `shift+alt` |
| `action` | `"click"` (par défaut) déclenche une fois / `"hold"` maintient tant que pressé |

### Touches prises en charge

**Modificateurs :** `shift`, `control`/`ctrl`, `alt`/`option`, `command`/`win`, `caps_lock` (variantes `left_`/`right_` toutes supportées)

**Exclusif macOS :** `fn`

**Touches de fonction :** `f1`-`f12`

**Touches courantes :** `escape`/`esc`, `return`/`enter`, `tab`, `space`, `backspace`/`delete`, `forward_delete`, `insert`

**Navigation :** `up`, `down`, `left`, `right`, `home`, `end`, `page_up`, `page_down`

**Lettres/Chiffres/Symboles :** `a`-`z`, `0`-`9`, `-`, `=`, `[`, `]`, `\`, `;`, `'`, `,`, `.`, `/`, `` ` ``

## Cas d'utilisation

- Latéral arrière → `Enter` — confirmation au pouce, productivité doublée en code/chat
- Latéral avant → `Alt` (mode maintien) — combiné au glisser souris = déplacement de fenêtre
- Milieu → `Escape` — annulation instantanée
- Bouton latéral → `Ctrl+C` / `Ctrl+V` — copier/coller d'une seule main
- Bouton latéral → `Command+Space` — lancement instantané de Spotlight / recherche

## Détails techniques

### Windows
- C + Win32 API, environ 960 lignes de code
- `SetWindowsHookEx(WH_MOUSE_LL)` interception par hook global
- `SendInput` sur thread de travail asynchrone pour la simulation de touches (évite le timeout du hook)
- Icône zone de notification + démarrage automatique via registre

### macOS
- Swift, environ 500 lignes de code
- `CGEventTap` interception d'événements au niveau session
- Double canal pour les modificateurs : IOKit (niveau système) + CGEvent (niveau application), résolvant le filtrage des événements synthétiques sous macOS
- Démarrage automatique via launchd

## Compilation

### Windows

GCC (MinGW-w64) requis :

```bash
cd windows
build.bat
```

### macOS

Swift 5.9+ requis :

```bash
swift build -c release
```

## License

MIT
