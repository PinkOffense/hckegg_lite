# 🚀 Deployment Guide - GitHub Pages

This guide will help you deploy the HCKEgg app to GitHub Pages so you can access it online.

---

## 📋 Prerequisites

Before deploying, ensure you have:

- ✅ GitHub account
- ✅ This repository forked or owned by you
- ✅ Git installed on your machine
- ✅ Flutter SDK installed (v3.38.1+)

---

## 🔧 One-Time Setup

### Step 1: Enable GitHub Pages

1. Go to your repository on GitHub
2. Click **Settings** (top menu)
3. Scroll to **Pages** (left sidebar)
4. Under **Source**, select:
   - Source: **GitHub Actions**
   - Click **Save**

### Step 2: Configure Repository Settings

The workflow is already configured for the repository name `hckegg_lite`. If your repository has a different name:

1. Open `.github/workflows/deploy-github-pages.yml`
2. Find the line: `flutter build web --release --base-href /hckegg_lite/`
3. Replace `hckegg_lite` with your repository name

Example:
```yaml
# If your repo is named "my-poultry-app"
flutter build web --release --base-href /my-poultry-app/
```

---

## 🚀 Automatic Deployment

### How It Works

The app **automatically deploys** when you push to the main branch:

```bash
# Make your changes
git add .
git commit -m "Update app"
git push origin main
```

The GitHub Actions workflow will:
1. ✅ Checkout your code
2. ✅ Install Flutter
3. ✅ Build the web app
4. ✅ Deploy to GitHub Pages

### Monitoring Deployment

1. Go to your repository on GitHub
2. Click **Actions** tab
3. See the deployment progress
4. Click on the workflow run for details

⏱️ **Deployment takes 2-5 minutes**

---

## 🌐 Accessing Your Deployed App

After successful deployment, your app will be available at:

```
https://<your-username>.github.io/hckegg_lite/
```

Examples:
- `https://PinkOffense.github.io/hckegg_lite/`
- `https://yourname.github.io/hckegg_lite/`

### Checking Deployment Status

1. Go to **Settings** → **Pages**
2. You'll see: "Your site is live at [URL]"
3. Click the URL to open your app

---

## 🛠️ Manual Deployment (Alternative)

If you prefer to deploy manually:

### Step 1: Build Locally

```bash
# Navigate to project
cd hckegg_lite

# Install dependencies
flutter pub get

# Build for web
flutter build web --release --base-href /hckegg_lite/
```

### Step 2: Deploy Using gh-pages Package

```bash
# Install gh-pages (one time)
npm install -g gh-pages

# Deploy
gh-pages -d build/web
```

Or using Git directly:

```bash
# Create gh-pages branch
git checkout --orphan gh-pages

# Add build files
cp -r build/web/* .

# Commit and push
git add .
git commit -m "Deploy to GitHub Pages"
git push origin gh-pages --force

# Switch back to main
git checkout main
```

---

## 🔧 Troubleshooting

### Deployment Fails

**Problem**: GitHub Actions workflow fails

**Solutions**:
1. Check the Actions tab for error details
2. Ensure Flutter version matches (3.38.1)
3. Verify pubspec.yaml dependencies are correct
4. Check if Pages is enabled in repository settings

### 404 Error When Accessing App

**Problem**: Page shows "404 - File not found"

**Solutions**:
1. Verify base-href in workflow matches repo name
2. Wait 2-5 minutes after deployment
3. Hard refresh browser (Ctrl+F5 / Cmd+Shift+R)
4. Check Pages settings show correct URL

### App Loads But Crashes

**Problem**: White screen or JavaScript errors

**Solutions**:
1. Check browser console (F12) for errors
2. Ensure build completed successfully
3. Try clearing browser cache
4. Test in different browser

### Styles Not Loading

**Problem**: App appears but looks broken

**Solutions**:
1. Verify base-href is correct
2. Check if all assets were deployed
3. Look for CORS errors in console
4. Rebuild with `flutter clean` first

---

## 🎨 Customization

### Custom Domain

To use your own domain (e.g., app.hckegg.com):

1. Buy a domain from a registrar
2. Add DNS records:
   - Type: `CNAME`
   - Name: `app` (or `www`)
   - Value: `<username>.github.io`
3. In repository **Settings** → **Pages**
4. Add custom domain: `app.hckegg.com`
5. Update workflow base-href to `/`

```yaml
flutter build web --release --base-href /
```

### Environment Variables

For production configurations:

1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Add secrets:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   - `FIREBASE_API_KEY`

3. Update workflow to use them:

```yaml
- name: Build for web
  env:
    SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
    SUPABASE_KEY: ${{ secrets.SUPABASE_ANON_KEY }}
  run: flutter build web --release --base-href /hckegg_lite/
```

---

## 📱 Progressive Web App (PWA)

Your app is already configured as a PWA! Users can:

1. Visit the deployed URL
2. Click browser menu (⋮)
3. Select "Install app" or "Add to home screen"
4. App works offline after first load

### PWA Features
- ✅ Offline support
- ✅ Install on mobile/desktop
- ✅ App icon on home screen
- ✅ Standalone window (no browser UI)
- ✅ Push notifications (if configured)

---

## 🔄 Updating the Deployed App

### Automatic Updates

1. Make changes to your code
2. Commit and push to main:
   ```bash
   git add .
   git commit -m "Feature: Added batch comparison"
   git push origin main
   ```
3. GitHub Actions automatically redeploys
4. Changes live in 2-5 minutes

### Versioning

Update version in `pubspec.yaml`:

```yaml
version: 1.0.0+1  # Change to 1.1.0+2
```

Then build and push:

```bash
git add pubspec.yaml
git commit -m "Bump version to 1.1.0"
git push origin main
```

---

## 📊 Analytics & Monitoring

### Enable Firebase Analytics

Already configured! Just add your Firebase config:

1. Create Firebase project
2. Add web app in Firebase console
3. Copy configuration
4. Update Firebase settings in app

### Monitor Performance

Check in GitHub Actions:
- Build time
- Bundle size
- Deployment success rate

---

## 🔐 Security Considerations

### API Keys

**Never commit API keys to public repos!**

Use GitHub Secrets for:
- Supabase keys
- Firebase configuration
- Third-party API tokens

### CORS Configuration

If using Supabase/Firebase:

1. Configure allowed origins in backend
2. Add your GitHub Pages URL:
   - `https://<username>.github.io`

---

## 📈 Performance Optimization

### Reduce Build Size

1. Enable code splitting (already configured)
2. Optimize images before adding
3. Use lazy loading for routes
4. Remove unused dependencies

### Cache Strategy

The app uses service workers for caching:
- Static assets cached indefinitely
- API calls cached with TTL
- Offline mode fully functional

---

## 🎯 Production Checklist

Before deploying to production:

- [ ] Update app name/branding in manifest.json
- [ ] Set correct base-href in workflow
- [ ] Configure Firebase/Supabase for production
- [ ] Add proper error tracking
- [ ] Test offline functionality
- [ ] Verify all features work on mobile
- [ ] Test in multiple browsers
- [ ] Set up custom domain (optional)
- [ ] Configure analytics
- [ ] Add privacy policy/terms

---

## 📞 Need Help?

- **GitHub Actions Docs**: https://docs.github.com/en/actions
- **GitHub Pages Docs**: https://docs.github.com/en/pages
- **Flutter Web Docs**: https://flutter.dev/web
- **Issues**: https://github.com/PinkOffense/hckegg_lite/issues

---

## 🎉 Success!

Your app is now live and accessible worldwide! Share the link with users and start collecting feedback.

**Next Steps**:
1. Share the URL with testers
2. Monitor the Actions tab for issues
3. Collect user feedback
4. Iterate and improve

---

*Happy Deploying! 🚀*

*HCKEgg © 2025*
