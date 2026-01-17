import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface User {
  id: number;
  email: string;
  firstName: string;
  lastName: string;
  sex: string;
  role: string;
  createdDate: Date;
  lastLoginDate?: Date;
}

export interface CreateUserRequest {
  email: string;
  password: string;
  firstName: string;
  lastName: string;
  sex: string;
  role: string;
}

export interface UpdateUserRequest {
  firstName: string;
  lastName: string;
  sex: string;
  role: string;
  newPassword?: string;
}

export interface UserCourse {
  id: number;
  categoryId: number;
  categoryName: string;
  name: string;
  path: string;
  createdDate: Date;
  subscribedDate?: Date;
}

@Injectable({ providedIn: 'root' })
export class UserService {
  private apiUrl = 'http://localhost:5000/api/users';
  private subscriptionUrl = 'http://localhost:5000/api/subscriptions';

  constructor(private http: HttpClient) {}

  getAllUsers(): Observable<User[]> {
    return this.http.get<User[]>(this.apiUrl);
  }

  getUser(id: number): Observable<User> {
    return this.http.get<User>(`${this.apiUrl}/${id}`);
  }

  createUser(request: CreateUserRequest): Observable<User> {
    return this.http.post<User>(this.apiUrl, request);
  }

  updateUser(id: number, request: UpdateUserRequest): Observable<User> {
    return this.http.put<User>(`${this.apiUrl}/${id}`, request);
  }

  deleteUser(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/${id}`);
  }

  getUserSubscriptions(userId: number): Observable<UserCourse[]> {
    return this.http.get<UserCourse[]>(`${this.apiUrl}/${userId}/subscriptions`);
  }

  subscribe(userId: number, courseId: number): Observable<any> {
    return this.http.post(`${this.subscriptionUrl}/subscribe`, { userId, courseId });
  }

  unsubscribe(userId: number, courseId: number): Observable<any> {
    return this.http.post(`${this.subscriptionUrl}/unsubscribe`, { userId, courseId });
  }

  getSubscribedCourseIds(userId: number): Observable<number[]> {
    return this.http.get<number[]>(`${this.subscriptionUrl}/user/${userId}/course-ids`);
  }
}
