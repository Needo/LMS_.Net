import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface SearchResult {
  id: number;
  courseId: number;
  courseName: string;
  categoryName: string;
  name: string;
  path: string;
  type: string;
  extension: string;
  size: number;
  parentId?: number;
}

@Injectable({ providedIn: 'root' })
export class SearchService {
  private apiUrl = 'http://localhost:5000/api/search';

  constructor(private http: HttpClient) {}

  search(query: string, userId?: number): Observable<SearchResult[]> {
    const params: any = { query };
    if (userId) {
      params.userId = userId;
    }
    return this.http.get<SearchResult[]>(this.apiUrl, { params });
  }
}
