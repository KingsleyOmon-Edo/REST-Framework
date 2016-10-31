﻿using A.Core.Interface;
using A.Core.Model;
using AutoMapper;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace $rootnamespace$.Core
{
    public partial class BaseMongoDbBasedCRUDService<TEntity, TSearchObject, TSearchAdditionalData, TInsert, TUpdate> : BaseMongoDbBasedReadService<TEntity, TSearchObject, TSearchAdditionalData>, ICRUDService<TEntity, TSearchObject, TSearchAdditionalData, TInsert, TUpdate>
        where TEntity : class, new()
        where TSearchAdditionalData : BaseAdditionalSearchRequestData, new()
        where TSearchObject : BaseSearchObject<TSearchAdditionalData>, new()
    {
        static BaseMongoDbBasedCRUDService()
        {
            Mapper.CreateMap<TInsert, TEntity>().ForAllMembers(opt => opt.Condition(srs => !srs.IsSourceValueNull));
            Mapper.CreateMap<TUpdate, TEntity>().ForAllMembers(opt => opt.Condition(srs => !srs.IsSourceValueNull));
        }

        [A.Core.Interceptors.LogInterceptor(AspectPriority = 0)]
        [A.Core.Interceptors.TransactionInterceptor(AspectPriority = 1)]
        public virtual TEntity Insert(TInsert request, bool saveChanges = true)
        {
            TEntity entity = CreateNewInstance();
            if (entity != null)
            {
                Mapper.Map<TInsert, TEntity>(request, entity);
                var validationResult = ValidateInsert(request, entity);
                if (validationResult.HasErrors)
                {
                    throw new A.Core.Validation.ValidationException(validationResult);
                }
                if (saveChanges)
                {
                    Save(entity);
                }
            }
            return entity;
        }

        public TEntity Update(object id, TUpdate request, bool saveChanges = true)
        {
            var entity = Get(id);
            if (entity != null)
            {
                Mapper.Map<TUpdate, TEntity>(request, entity);
                var validationResult = ValidateUpdate(request, entity);
                if (validationResult.HasErrors)
                {
                    throw new A.Core.Validation.ValidationException(validationResult);
                }
                if (saveChanges)
                {
                    Save(entity);
                }
            }
            return entity;
        }

        public virtual A.Core.Validation.ValidationResult ValidateInsert(TInsert request, TEntity entity)
        {
            A.Core.Validation.ValidationResult result = new A.Core.Validation.ValidationResult();

            var context = new ValidationContext(request, serviceProvider: null, items: null);
            var validationResults = new List<ValidationResult>();

            bool isValid = Validator.TryValidateObject(request, context, validationResults, true);
            if (!isValid)
            {
                validationResults.ForEach(x => { result.ResultList.Add(new A.Core.Validation.ValidationResultItem() { Key = x.MemberNames.First(), Description = x.ErrorMessage }); });
            }
            return result;
        }

        public virtual A.Core.Validation.ValidationResult ValidateUpdate(TUpdate request, TEntity entity)
        {
            A.Core.Validation.ValidationResult result = new A.Core.Validation.ValidationResult();

            var context = new ValidationContext(request, serviceProvider: null, items: null);
            var validationResults = new List<ValidationResult>();

            bool isValid = Validator.TryValidateObject(request, context, validationResults, true);
            if (!isValid)
            {
                validationResults.ForEach(x => { result.ResultList.Add(new A.Core.Validation.ValidationResultItem() { Key = x.MemberNames.First(), Description = x.ErrorMessage }); });
            }
            return result;
        }
    }
}
