# PDF.js Custom Viewer Implementation

## Installation Required

Please run the following command to install PDF.js:

```powershell
cd C:\LMSSystem\LMSUI
npm install pdfjs-dist@3.11.174
```

Or run the provided script:
```powershell
.\install-pdfjs.ps1
```

## Features

The custom PDF viewer provides:
- ✅ **Persistent bookmarks panel** - Stays open when you click bookmarks
- ✅ Page navigation (Previous/Next)
- ✅ Zoom controls (In/Out)
- ✅ Fit to width
- ✅ Page counter
- ✅ Hierarchical bookmark navigation
- ✅ Dark theme matching the app

## Files Created

1. `C:\LMSSystem\LMSUI\src\app\components\pdf-viewer\pdf-viewer.component.ts` - Custom PDF viewer
2. `C:\LMSSystem\install-pdfjs.ps1` - Installation script

## Files Modified

1. `C:\LMSSystem\LMSUI\src\app\components\viewer\viewer.component.ts` - Updated to use custom PDF viewer

## Usage

After installing the package, restart your Angular dev server:
```bash
ng serve
```

The PDF viewer will automatically replace the browser's iframe-based viewer.

## Benefits Over iframe

- Full control over UI/UX
- Bookmarks panel stays open when navigating
- Better integration with app theme
- Custom toolbar controls
- No browser-specific limitations
