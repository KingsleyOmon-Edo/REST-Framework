import { Component, ViewChild, AfterViewInit, OnInit } from '@angular/core';
import { MatPaginator, MatSort} from '@angular/material';
import { Location } from '@angular/common';
import {ActivatedRoute, Router} from '@angular/router';
import {FormlyFieldConfig} from '@ngx-formly/core';
import {FormGroup} from '@angular/forms';

import { PageTitleService } from 'app/shared/services/page-title.service';
import { CountryService } from '../country.service';

@Component({
  selector: 'country-list',
  templateUrl: './country-list.component.html',
  styleUrls: ['./country-list.component.scss']
})
export class CountryListComponent implements OnInit, AfterViewInit {
        // REGION:Common Variables
        isLoading = false;
        searchObject: any = {
          page: 0,
          pageSize: 10,
          countEnabled: false,
          // add filters here
          nameGTE: null
        };
        searchObjectClone = {}; //holds initial search object so that we can clear search
        form = new FormGroup({});
        fields: FormlyFieldConfig[] = [{
            fieldGroupClassName: 'row', //on root wee don't need it
            fieldGroup: [
                {
                    className: 'col col-lg-4',
                    type: 'input',
                    key: 'nameGTE',
                    templateOptions: {
                        translate: true,
                        label: 'GENERAL.SEARCH'
                    },
                }
            ],
        }];

      searchResult: any = {count: 100, resultList: []}; // leave room for hasMore flag
      displayedColumns: string[] = [
      'code', 'name', 
      
      ]
      @ViewChild(MatPaginator, {static: false}) paginator: MatPaginator;
      @ViewChild(MatSort, {static: false}) sort: MatSort;

      constructor(public mainService: CountryService,
                     private location: Location,
                     private router: Router,
                     protected activatedRoute: ActivatedRoute,
                     private pageTitleService: PageTitleService,
                     ) {
      }

      async ngOnInit() {
          this.pageTitleService.setTitle('Views.' + 'CountryList');
              await this.init();
      }

      private async init() {
          Object.assign(this.searchObjectClone, this.searchObject);
           
          this.activatedRoute.queryParams.subscribe(async x => {
              if (x.__query) {
                  const search = JSON.parse(atob(x.__query));
                  Object.assign(this.searchObject, search);
                  this.searchObject.countEnabled = true;
                  await this.searchInternal();
              } else {
                  this.searchObject = {};
                  Object.assign(this.searchObject, this.searchObjectClone);
                  await this.search(true);
              }
          });
          
      }

      async search(countEnabled = false) {
              this.searchObject.countEnabled = countEnabled; // reverse logic
              if (countEnabled === true) {
                  this.searchObject.page = 0;
              }
              await this.searchInternal();
      }

      private async searchInternal() {
          this.isLoading = true;
          const result = (await this.mainService.getPage(this.searchObject));
          if (this.searchObject.countEnabled) {
              this.searchResult.count = result.count || this.searchResult.count;
          }
           this.writeToQueryString(); 
          this.searchResult.resultList = result.resultList;
          this.isLoading = false;
          return result;
      }
      
      private writeToQueryString() {
          const urlParts = this.router.url.split('?');
          let url = urlParts[0];
          const urlParams = new URLSearchParams(urlParts[urlParts.length - 1]);
          urlParams.delete('__query');

          url = url.split('?')[0] + '?';
          urlParams.append('__query', btoa(JSON.stringify(this.searchObject)));
          let params = '';
          urlParams.forEach((value, key) => {
              if (value && value !== '') {
                  params += key + '=' + value + '&';
              }
          });
          url += params;
          this.location.replaceState(url);
      }
      
      ngAfterViewInit(): void {
          this.paginator.page.subscribe( async(page) => {
              const reload = this.searchObject.pageSize !== page.pageSize;
              this.searchObject.page = page.pageIndex;
              this.searchObject.pageSize = page.pageSize;
              await this.search(reload);
          });
          this.sort.sortChange.subscribe((event) =>  {
              this.searchObject.page = 0;
              this.searchObject.orderBy = event.active + " " + event.direction.toUpperCase();
              this.search(true);
          });
      }

      async clear() {
          this.searchObject = {};
          Object.assign(this.searchObject, this.searchObjectClone);
          await this.search(true);
      }

      details(row) {
          this.router.navigate(['xcore/country', row.id]);
      }

      
}
