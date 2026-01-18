# Authentication & Search Implementation - Status

## ✅ Completed Files:

### Backend:
1. ✅ `SearchController.cs` - Search API endpoint
   - GET `/api/search?query=...&userId=...`
   - Searches CourseItems by name
   - Filters by user subscriptions if userId provided
   - Returns results with course and category info

### Frontend Services:
1. ✅ `auth.service.ts` - Authentication service
   - Login/logout functionality
   - Stores current user in localStorage
   - Observable currentUser$ for reactive updates
   - isAdmin helper property

2. ✅ `search.service.ts` - Search service
   - search(query, userId?) method
   - Returns SearchResult[]

### Frontend Components:
1. ✅ `header.component.ts` - Updated header
   - Search box in center
   - User menu with name, email, role
   - Login/Logout buttons
   - Admin panel link (if admin)

2. ✅ `login.component.ts` - Login page
   - Email/password form
   - Error handling
   - Loading spinner
   - Responsive design

## 📋 TODO - Required Next Steps:

### Step 1: Update Main Layout to Handle Search
File: `main-layout.component.ts`

Add search results panel:
```typescript
// Add properties
searchResults: SearchResult[] = [];
showSearchResults = false;

// Add method
onSearch(query: string) {
  if (!query) {
    this.showSearchResults = false;
    return;
  }
  const userId = this.authService.currentUser?.id;
  this.searchService.search(query, userId).subscribe(results => {
    this.searchResults = results;
    this.showSearchResults = true;
  });
}

// Update template to pass search event
<app-header (search)="onSearch($event)"></app-header>

// Add search results panel
@if (showSearchResults) {
  <div class="viewer-wrapper">
    <app-search-results 
      [results]="searchResults"
      (itemSelected)="navigateToItem($event)"
      (close)="showSearchResults = false">
    </app-search-results>
  </div>
} @else {
  <div class="viewer-wrapper">
    <app-viewer [selectedItem]="selectedItem"></app-viewer>
  </div>
}
```

### Step 2: Create Search Results Component
File: `search-results.component.ts`

- Table showing: Name, Course, Category, Type, Size
- Click row to navigate to file in tree
- Close button to return to viewer

### Step 3: Filter Sidebar by User Subscriptions
File: `sidebar.component.ts`

Update to only show subscribed courses:
```typescript
loadCategories() {
  const userId = this.authService.currentUser?.id;
  
  // Get user's subscribed course IDs
  this.userService.getSubscribedCourseIds(userId).subscribe(courseIds => {
    this.subscribedCourseIds = courseIds;
    
    // Then load categories (filter courses client-side)
    this.courseService.getCategories().subscribe(categories => {
      // Filter and process categories
    });
  });
}
```

### Step 4: Update Routes
File: `app.routes.ts`

```typescript
export const routes: Routes = [
  { path: 'login', component: LoginComponent },
  { 
    path: '', 
    component: MainLayoutComponent,
    canActivate: [AuthGuard] // Add auth guard
  },
  {
    path: 'admin',
    component: AdminComponent,
    canActivate: [AuthGuard, AdminGuard]
  },
  { path: '**', redirectTo: '' }
];
```

### Step 5: Create Auth Guard
File: `auth.guard.ts`

```typescript
export const AuthGuard: CanActivateFn = () => {
  const authService = inject(AuthService);
  const router = inject(Router);
  
  if (authService.isLoggedIn) {
    return true;
  }
  
  router.navigate(['/login']);
  return false;
};
```

### Step 6: Create Admin Guard
File: `admin.guard.ts`

```typescript
export const AdminGuard: CanActivateFn = () => {
  const authService = inject(AuthService);
  const router = inject(Router);
  
  if (authService.isAdmin) {
    return true;
  }
  
  router.navigate(['/']);
  return false;
};
```

### Step 7: Navigate to Item in Tree
File: `main-layout.component.ts`

Add method to expand tree to specific item:
```typescript
navigateToItem(searchResult: SearchResult) {
  // 1. Close search results
  this.showSearchResults = false;
  
  // 2. Expand category -> course -> folders path
  // 3. Select the item
  // This requires adding a method to sidebar component
  this.sidebar.expandToItem(searchResult);
}
```

### Step 8: Add Expand Method to Sidebar
File: `sidebar.component.ts`

```typescript
async expandToItem(item: SearchResult) {
  // 1. Find and expand category
  const category = this.categories.find(c => c.name === item.categoryName);
  if (category && !category.expanded) {
    await this.toggleNode(category);
  }
  
  // 2. Find and expand course
  const course = category.children?.find(c => c.id === item.courseId);
  if (course && !course.expanded) {
    await this.toggleNode(course);
  }
  
  // 3. Expand parent folders recursively if needed
  // 4. Select the final item
}
```

## 🎯 Testing Checklist:

### Authentication:
- [ ] Can login with valid credentials
- [ ] See error message with invalid credentials
- [ ] User info shows in header after login
- [ ] Can logout
- [ ] Redirected to login when not authenticated
- [ ] Admin can access admin panel
- [ ] Student cannot access admin panel

### Search:
- [ ] Search box appears in header
- [ ] Typing and pressing Enter triggers search
- [ ] Search results appear in table
- [ ] Results filtered by user's subscribed courses
- [ ] Clicking result navigates to item in tree
- [ ] Tree expands to show the item
- [ ] Item is selected and opens in viewer

### Subscriptions:
- [ ] Sidebar only shows subscribed courses
- [ ] Search only returns results from subscribed courses
- [ ] Admin can see all courses

## 📝 Files Summary:

**Created (7 files):**
1. Backend: SearchController.cs
2. Services: auth.service.ts, search.service.ts
3. Components: header.component.ts (updated), login.component.ts
4. Guards: auth.guard.ts, admin.guard.ts (to create)

**To Update (3 files):**
1. main-layout.component.ts - Add search handling
2. sidebar.component.ts - Filter by subscriptions
3. app.routes.ts - Add guards

**To Create (1 file):**
1. search-results.component.ts - Search results table

## 🚀 Quick Start:

```bash
# Backend
cd C:\LMSSystem\LMS.API
dotnet run

# Frontend
cd C:\LMSSystem\LMSUI
ng serve
```

Then navigate to http://localhost:4200/login

Default test user:
- Email: test@test.com
- Password: password123

(Create via Admin Panel -> User Management)

---

**Current Status**: Backend complete, Frontend 60% complete
**Next**: Create search results component and update main layout
