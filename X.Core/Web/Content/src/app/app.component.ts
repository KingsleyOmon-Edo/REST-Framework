import {Component, Optional, ViewEncapsulation} from '@angular/core';
import { TranslateService} from '@ngx-translate/core';
import { OAuthService, JwksValidationHandler } from 'angular-oauth2-oidc';
import { environment } from 'environments/environment';
import { TranslateExtService } from './shared/services/translate-ext.service';
import { LoadingBarService } from '@ngx-loading-bar/core';
import { map, take, delay, withLatestFrom, finalize, tap } from 'rxjs/operators';

@Component({
  	selector: 'gene-app',
   template:`<router-outlet></router-outlet>
   			<ngx-loading-bar  [value]="(delayedProgress$|async) || 0"></ngx-loading-bar>`,
   encapsulation: ViewEncapsulation.None
})

export class GeneAppComponent {

   delayedProgress$ = this.loader.progress$.pipe(
      delay(2000),
      withLatestFrom(this.loader.progress$),
      map(v => v[1]),
    );

   constructor(translate: TranslateService, translateExtService: TranslateExtService, private oauthService: OAuthService, public loader: LoadingBarService) {
      translate.addLangs(['bs', 'en']);
      if (localStorage.getItem('core.language')) {
         translateExtService.setLocale(localStorage.getItem('core.language'));
       } else {
         translateExtService.setLocale('bs');
       }

      this.auth();
   }

   auth() {
      this.oauthService.configure(environment.auth);
      this.oauthService.tokenValidationHandler = new JwksValidationHandler();
      this.oauthService.loadDiscoveryDocumentAndTryLogin({
         onTokenReceived: context => {
            
         }
      });
   }
}