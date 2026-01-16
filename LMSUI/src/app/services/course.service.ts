import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Course, CourseItem, Category } from '../models/course.model';

@Injectable({ providedIn: 'root' })
export class CourseService {
  private apiUrl = 'http://localhost:5000/api';
  constructor(private http: HttpClient) {}
  
  getCategories(): Observable<Category[]> {
    return this.http.get<Category[]>(`${this.apiUrl}/courses/categories`);
  }
  
  getCourses(): Observable<Course[]> {
    return this.http.get<Course[]>(`${this.apiUrl}/courses`);
  }
  
  getCoursesByCategory(categoryId: number): Observable<Course[]> {
    return this.http.get<Course[]>(`${this.apiUrl}/courses/categories/${categoryId}/courses`);
  }
  
  getCourseItems(courseId: number): Observable<CourseItem[]> {
    return this.http.get<CourseItem[]>(`${this.apiUrl}/courses/${courseId}/items`);
  }
  
  getFolderContents(folderId: number): Observable<CourseItem[]> {
    return this.http.get<CourseItem[]>(`${this.apiUrl}/courses/folders/${folderId}/contents`);
  }
  
  scanCourses(rootPath: string): Observable<any> {
    return this.http.post(`${this.apiUrl}/courses/scan`, { rootPath });
  }
  
  getFileUrl(path: string): string {
    return `${this.apiUrl}/files?path=${encodeURIComponent(path)}`;
  }
}
