# How to Publish STACK Intelligence to GitHub Pages

Follow these steps to get your site live at a free public URL like:
`https://YOUR-USERNAME.github.io/stack-intelligence/`

---

## Step 1 — Create a GitHub Account (skip if you have one)

1. Go to [github.com](https://github.com) and click **Sign up**
2. Choose a username (e.g. `dustale` or your company name)
3. Verify your email

---

## Step 2 — Create a New Repository

1. Once logged in, click the **+** icon in the top-right → **New repository**
2. Fill in:
   - **Repository name:** `stack-intelligence`
   - **Visibility:** Public *(required for free GitHub Pages)*
   - **Description:** STACK Intelligence Platform
3. Leave everything else unchecked
4. Click **Create repository**

---

## Step 3 — Install Git (if not already installed)

Open your Terminal (Mac) and run:

```bash
git --version
```

If it says "command not found", download Git from [git-scm.com](https://git-scm.com/downloads) and install it.

---

## Step 4 — Push Your Files to GitHub

Open Terminal and run these commands one at a time.

Replace `YOUR-USERNAME` with your actual GitHub username.

```bash
# 1. Navigate to your project folder
cd "/Users/dustale/Documents/Claude/Projects/STACK Intelegence"

# 2. Initialize a git repository
git init

# 3. Add your files
git add .

# 4. Create your first commit
git commit -m "Initial commit: STACK Intelligence Platform"

# 5. Connect to your GitHub repo
git remote add origin https://github.com/YOUR-USERNAME/stack-intelligence.git

# 6. Push your code
git branch -M main
git push -u origin main
```

GitHub will ask for your username and password the first time.
> **Note:** GitHub no longer accepts passwords — you'll need a **Personal Access Token** instead of your password. Create one at: GitHub → Settings → Developer Settings → Personal Access Tokens → Tokens (classic) → Generate new token. Give it `repo` scope.

---

## Step 5 — Enable GitHub Pages

1. Go to your repository on GitHub: `github.com/YOUR-USERNAME/stack-intelligence`
2. Click **Settings** (top tab)
3. In the left sidebar, click **Pages**
4. Under **Source**, select:
   - Branch: `main`
   - Folder: `/ (root)`
5. Click **Save**

GitHub will show a green banner with your live URL within 1–2 minutes:
```
Your site is published at https://YOUR-USERNAME.github.io/stack-intelligence/
```

---

## Step 6 — Making Updates Later

Whenever you change `index.html`, just run:

```bash
cd "/Users/dustale/Documents/Claude/Projects/STACK Intelegence"
git add .
git commit -m "Update: describe what changed"
git push
```

Your site will automatically update within a minute or two.

---

## Optional: Use a Custom Domain

If you have a domain (e.g. `stackintelligence.com`):

1. In GitHub Pages settings → add your custom domain
2. At your domain registrar, add a CNAME record pointing to `YOUR-USERNAME.github.io`
3. GitHub will issue a free HTTPS certificate automatically

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Push rejected (authentication) | Use a Personal Access Token instead of password |
| Site not showing up | Wait 2-3 min; check Settings → Pages for errors |
| 404 error | Make sure the file is named exactly `index.html` |
| Changes not showing | Hard-refresh the page (Cmd+Shift+R on Mac) |

---

*Questions? Open an issue on your GitHub repo or email dustale@gmail.com*
