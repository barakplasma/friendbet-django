import { Injectable, signal, computed } from '@angular/core';
import { Router } from '@angular/router';
import { Observable, BehaviorSubject, from, of } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class PocketbaseService {
  private pb: any;
  private authStateSubject = new BehaviorSubject<any>(null);
  public authState$ = this.authStateSubject.asObservable();

  // PocketBase server URL
  private readonly PB_URL = 'http://localhost:8090';

  constructor(private router: Router) {
    this.initializePocketBase();
  }

  private initializePocketBase() {
    // Load PocketBase SDK dynamically
    import('pocketbase/dist/pocketbase.es.mjs').then((module) => {
      const PocketBase = (module as any).default;
      this.pb = new PocketBase(this.PB_URL);

      // Initialize auth state from stored token
      this.pb.authStore.loadFromCookie(document.cookie);
      
      if (this.pb.authStore.isValid) {
        this.authStateSubject.next(this.pb.authStore.model);
      }

      // Listen to auth changes
      this.pb.authStore.onChange((token: string, model: any) => {
        this.authStateSubject.next(model);
      });
    }).catch(err => {
      console.error('Failed to load PocketBase:', err);
    });
  }

  get currentUser() {
    return this.authStateSubject.value;
  }

  get isAuthenticated(): boolean {
    return this.pb?.authStore?.isValid || false;
  }

  // OAuth Methods
  async loginWithGoogle(): Promise<void> {
    try {
      const authData = await this.pb.collection('users').authWithOAuth2({ 
        provider: 'google',
        redirectUrl: `${window.location.origin}/auth/callback`
      });
      
      this.authStateSubject.next(authData.record);
      this.router.navigate(['/dashboard']);
    } catch (error) {
      console.error('Google login failed:', error);
      throw error;
    }
  }

  async loginWithGitHub(): Promise<void> {
    try {
      const authData = await this.pb.collection('users').authWithOAuth2({ 
        provider: 'github',
        redirectUrl: `${window.location.origin}/auth/callback`
      });
      
      this.authStateSubject.next(authData.record);
      this.router.navigate(['/dashboard']);
    } catch (error) {
      console.error('GitHub login failed:', error);
      throw error;
    }
  }

  async loginWithMicrosoft(): Promise<void> {
    try {
      const authData = await this.pb.collection('users').authWithOAuth2({ 
        provider: 'microsoft',
        redirectUrl: `${window.location.origin}/auth/callback`
      });
      
      this.authStateSubject.next(authData.record);
      this.router.navigate(['/dashboard']);
    } catch (error) {
      console.error('Microsoft login failed:', error);
      throw error;
    }
  }

  async logout(): Promise<void> {
    this.pb?.authStore.clear();
    this.authStateSubject.next(null);
    this.router.navigate(['/login']);
  }

  // Generic PocketBase Methods
  async getList(collection: string, page = 1, perPage = 20, options = {}) {
    return await this.pb.collection(collection).getList(page, perPage, options);
  }

  async getOne(collection: string, id: string) {
    return await this.pb.collection(collection).getOne(id);
  }

  async create(collection: string, data: any) {
    return await this.pb.collection(collection).create(data);
  }

  async update(collection: string, id: string, data: any) {
    return await this.pb.collection(collection).update(id, data);
  }

  async delete(collection: string, id: string) {
    return await this.pb.collection(collection).delete(id);
  }

  // Real-time subscription
  subscribe(collection: string, callback: (data: any) => void) {
    return this.pb.collection(collection).subscribe('*', callback);
  }

  unsubscribe(subscription: any) {
    this.pb.unsubscribe(subscription);
  }
}