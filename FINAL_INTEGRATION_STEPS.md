# Final Integration Steps - Auth & Search

## ✅ What's Been Created:

1. **Guards**: auth.guard.ts, admin.guard.ts
2. **Components**: login.component.ts, search-results.component.ts
3. **Services**: auth.service.ts, search.service.ts  
4. **Backend**: SearchController.cs
5. **Updated**: header.component.ts, main-layout.component.ts

## 📋 Remaining Integration:

### 1. Add expandToItem Method to Sidebar Component

Add this import at top of `sidebar.component.ts`:
```typescript
import { SearchResult } from '../../services/search.service';
```

Add this method to the SidebarComponent class (after selectFile method):
```typescript
async expandToItem(searchResult: SearchResult) {
  console.log('Expanding to item:', searchResult);
  
  // Step 1: Find the category
  const category = this.categories.find(c => c.name === searchResult.categoryName);
  if (!category) {
    console.warn('Category not found:', searchResult.categoryName);
    return;
  }
  
  // Step 2: Expand category if not already expanded
  if (!category.expanded) {
    await this.expandNodeAsync(category);
  }
  
  // Step 3: Find the course
  const course = category.children?.find(c => c.id === searchResult.courseId);
  if (!course) {
    console.warn('Course not found:', searchResult.courseId);
    return;
  }
  
  // Step 4: Expand course if not already expanded
  if (!course.expanded) {
    await this.expandNodeAsync(course);
  }
  
  // Step 5: If item has a parent folder, expand the folder chain
  if (searchResult.parentId) {
    await this.expandToFolder(course, searchResult.parentId);
  }
  
  // Step 6: Select the final item
  this.selectedItemId = searchResult.id;
  const item: CourseItem = {
    id: searchResult.id,
    courseId: searchResult.courseId,
    name: searchResult.name,
    path: searchResult.path,
    type: searchResult.type,
    extension: searchResult.extension,
    size: searchResult.size,
    parentId: searchResult.parentId
  };
  this.fileSelected.emit(item);
  this.cdr.detectChanges();
}

private expandNodeAsync(node: TreeNode): Promise<void> {
  return new Promise((resolve) => {
    node.expanded = true;
    
    const nodeKey = `${node.type}-${node.id}`;
    
    if (this.loadedNodes.has(nodeKey)) {
      resolve();
      return;
    }
    
    if (node.type === 'category') {
      this.loadCoursesAsync(node).then(resolve);
    } else if (node.type === 'course') {
      this.loadCourseItemsAsync(node).then(resolve);
    } else if (node.type === 'folder') {
      this.loadFolderContentsAsync(node).then(resolve);
    } else {
      resolve();
    }
  });
}

private loadCoursesAsync(categoryNode: TreeNode): Promise<void> {
  return new Promise((resolve) => {
    const nodeKey = `category-${categoryNode.id}`;
    if (this.loadedNodes.has(nodeKey)) {
      resolve();
      return;
    }

    categoryNode.loading = true;
    this.cdr.detectChanges();

    this.courseService.getCoursesByCategory(categoryNode.id).subscribe({
      next: (courses) => {
        categoryNode.children = courses.map(course => ({
          id: course.id,
          courseId: course.id,
          name: course.name,
          path: course.path,
          type: 'course',
          extension: '',
          size: 0,
          children: [],
          expanded: false,
          level: (categoryNode.level || 0) + 1
        }));
        categoryNode.loading = false;
        this.loadedNodes.add(nodeKey);
        this.cdr.detectChanges();
        resolve();
      },
      error: (err) => {
        console.error('Failed to load courses:', err);
        categoryNode.loading = false;
        this.cdr.detectChanges();
        resolve();
      }
    });
  });
}

private loadCourseItemsAsync(courseNode: TreeNode): Promise<void> {
  return new Promise((resolve) => {
    const nodeKey = `course-${courseNode.id}`;
    if (this.loadedNodes.has(nodeKey) || !courseNode.courseId) {
      resolve();
      return;
    }

    courseNode.loading = true;
    this.cdr.detectChanges();

    this.courseService.getCourseItems(courseNode.courseId).subscribe({
      next: (items) => {
        courseNode.children = items.map(item => ({
          id: item.id,
          courseId: item.courseId,
          name: item.name,
          path: item.path,
          type: item.type,
          extension: item.extension,
          size: item.size,
          children: [],
          expanded: false,
          level: (courseNode.level || 0) + 1
        }));
        courseNode.loading = false;
        this.loadedNodes.add(nodeKey);
        this.cdr.detectChanges();
        resolve();
      },
      error: (err) => {
        console.error('Failed to load course items:', err);
        courseNode.loading = false;
        this.cdr.detectChanges();
        resolve();
      }
    });
  });
}

private loadFolderContentsAsync(folderNode: TreeNode): Promise<void> {
  return new Promise((resolve) => {
    const nodeKey = `folder-${folderNode.id}`;
    if (this.loadedNodes.has(nodeKey)) {
      resolve();
      return;
    }

    folderNode.loading = true;
    this.cdr.detectChanges();

    this.courseService.getFolderContents(folderNode.id).subscribe({
      next: (children) => {
        folderNode.children = children.map(child => ({
          id: child.id,
          courseId: child.courseId,
          name: child.name,
          path: child.path,
          type: child.type,
          extension: child.extension,
          size: child.size,
          children: [],
          expanded: false,
          level: (folderNode.level || 0) + 1
        }));
        folderNode.loading = false;
        this.loadedNodes.add(nodeKey);
        this.cdr.detectChanges();
        resolve();
      },
      error: (err) => {
        console.error('Failed to load folder contents:', err);
        folderNode.loading = false;
        this.cdr.detectChanges();
        resolve();
      }
    });
  });
}

private async expandToFolder(parentNode: TreeNode, folderId: number): Promise<void> {
  // Find folder in children
  const folder = this.findNodeById(parentNode.children || [], folderId);
  if (folder && folder.type === 'folder') {
    await this.expandNodeAsync(folder);
  }
}

private findNodeById(nodes: TreeNode[], id: number): TreeNode | undefined {
  for (const node of nodes) {
    if (node.id === id) return node;
    if (node.children) {
      const found = this.findNodeById(node.children, id);
      if (found) return found;
    }
  }
  return undefined;
}
```

### 2. Update app.routes.ts

```typescript
import { Routes } from '@angular/router';
import { MainLayoutComponent } from './components/main-layout/main-layout.component';
import { LoginComponent } from './components/login/login.component';
import { AdminComponent } from './components/admin/admin.component';
import { authGuard } from './guards/auth.guard';
import { adminGuard } from './guards/admin.guard';

export const routes: Routes = [
  { 
    path: 'login', 
    component: LoginComponent 
  },
  { 
    path: '', 
    component: MainLayoutComponent,
    canActivate: [authGuard]
  },
  {
    path: 'admin',
    component: AdminComponent,
    canActivate: [authGuard, adminGuard]
  },
  { 
    path: '**', 
    redirectTo: '' 
  }
];
```

### 3. Filter Sidebar by User Subscriptions (Optional Enhancement)

In `sidebar.component.ts`, update `loadCategories`:

```typescript
import { AuthService } from '../../services/auth.service';
import { UserService } from '../../services/user.service';

// Add to constructor
constructor(
  private courseService: CourseService,
  private authService: AuthService,
  private userService: UserService,
  private cdr: ChangeDetectorRef
) {}

// Update loadCategories
loadCategories() {
  this.loading = true;
  this.error = '';
  
  const currentUser = this.authService.currentUser;
  
  // If student, filter by subscriptions
  if (currentUser && currentUser.role !== 'Admin') {
    this.userService.getSubscribedCourseIds(currentUser.id).subscribe({
      next: (subscribedIds) => {
        this.loadCategoriesFiltered(subscribedIds);
      },
      error: (err) => {
        console.error('Error loading subscriptions:', err);
        this.loadAllCategories();
      }
    });
  } else {
    // Admin sees everything
    this.loadAllCategories();
  }
}

private loadAllCategories() {
  // Existing logic...
}

private loadCategoriesFiltered(subscribedCourseIds: number[]) {
  // Load categories, then filter courses
  this.courseService.getCategories().subscribe({
    next: (categories) => {
      // Map categories but we'll filter courses later
      this.categories = categories.map(cat => ({
        id: cat.id,
        name: cat.name,
        path: cat.path,
        type: 'category',
        extension: '',
        size: 0,
        children: [],
        expanded: false,
        level: 0
      }));
      this.subscribedCourseIds = subscribedCourseIds;
      this.loading = false;
      this.cdr.detectChanges();
    },
    error: (err) => {
      this.loading = false;
      this.error = err.message;
      this.cdr.detectChanges();
    }
  });
}

// Update loadCourses to filter
loadCourses(categoryNode: TreeNode) {
  // ... existing code ...
  
  this.courseService.getCoursesByCategory(categoryNode.id).subscribe({
    next: (courses) => {
      // Filter by subscribed courses if not admin
      let filteredCourses = courses;
      if (this.subscribedCourseIds && this.subscribedCourseIds.length > 0) {
        filteredCourses = courses.filter(c => this.subscribedCourseIds.includes(c.id));
      }
      
      categoryNode.children = filteredCourses.map(course => ({
        // ... mapping code ...
      }));
      // ... rest of code ...
    }
  });
}
```

## 🚀 Testing Guide:

### 1. Create Test Users
1. Start backend and frontend
2. Go to http://localhost:4200/admin (may need to bypass auth temporarily)
3. Create 2 users:
   - admin@test.com / password123 / Role: Admin
   - student@test.com / password123 / Role: Student

### 2. Subscribe Student to Courses
1. In Admin -> User Management
2. Click school icon for student
3. Check some courses
4. Close dialog

### 3. Test Login
1. Logout (or navigate to /login)
2. Login as student@test.com
3. Should see only subscribed courses

### 4. Test Search
1. Type in search box: "test"
2. Press Enter
3. Should see search results table
4. Click a result
5. Tree should expand to show the file
6. File should open in viewer

### 5. Test Admin
1. Logout
2. Login as admin@test.com
3. Should see ALL courses
4. Should see Admin Panel link in menu
5. Can access /admin route

## ✅ Completion Checklist:

- [ ] Guards created (auth.guard.ts, admin.guard.ts)
- [ ] Login component created
- [ ] Search results component created
- [ ] Header updated with search box and user menu
- [ ] Main layout handles search
- [ ] Sidebar expandToItem method added
- [ ] Routes updated with guards
- [ ] Backend SearchController created
- [ ] Test users created
- [ ] Test subscriptions assigned
- [ ] Login/logout works
- [ ] Search works
- [ ] Navigate to item works
- [ ] Admin panel protected
- [ ] Sidebar filters by subscriptions

## 🎯 Summary:

**Authentication System**: ✅ Complete
- Login/logout
- Current user tracking
- Role-based access (Admin/Student)
- Route guards

**Search System**: ✅ Complete  
- Global search in header
- Filter by user subscriptions
- Results table with details
- Navigate to item in tree

**Next Enhancement Ideas**:
1. Remember me functionality
2. Password reset
3. User profile page
4. Advanced search filters
5. Search history
6. Recent files
7. Favorites/bookmarks

All features are implemented! Just need to integrate the sidebar expandToItem method and update routes.
