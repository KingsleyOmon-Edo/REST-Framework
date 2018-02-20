using A.Core.Interface;
using A.Core.Model;
using AutoMapper;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using AutoMapper.Internal;
using A.Core.Interceptors;
using Autofac.Extras.DynamicProxy;

namespace $rootnamespace$.Core //DD
{
    public partial class BaseMongoDbBasedCRUDServiceAsync<TEntity, TSearchObject, TSearchAdditionalData, TInsert, TUpdate> : BaseMongoDbBasedReadServiceAsync<TEntity, TSearchObject, TSearchAdditionalData>, ICRUDServiceAsync<TEntity, TSearchObject, TSearchAdditionalData, TInsert, TUpdate>
        where TEntity : class, new()
        where TSearchAdditionalData : BaseAdditionalSearchRequestData, new()
        where TSearchObject : BaseSearchObject<TSearchAdditionalData>, new()
    {
        // ReSharper disable once StaticMemberInGenericType
        public static IMapper Mapper { get; set; }
        // ReSharper disable once StaticMemberInGenericType
        public static IMapper AllFieldsMapper { get; set; }

        static BaseMongoDbBasedCRUDServiceAsync()
        {

            var config = new MapperConfiguration(cfg =>
            {
                cfg.ForAllPropertyMaps(pm => !pm.HasSource(),
                    (pm, opt) => opt.UseDestinationValue());
                cfg.CreateMap<long?, long>().ConvertUsing((src, dest) => src ?? dest);
                cfg.CreateMap<int?, int>().ConvertUsing((src, dest) => src ?? dest);
                cfg.CreateMap<short?, short>().ConvertUsing((src, dest) => src ?? dest);
                cfg.CreateMap<byte?, byte>().ConvertUsing((src, dest) => src ?? dest);
                cfg.CreateMap<bool?, bool>().ConvertUsing((src, dest) => src ?? dest);
                cfg.CreateMap<decimal?, decimal>().ConvertUsing((src, dest) => src ?? dest);
                cfg.CreateMap<DateTime?, DateTime>().ConvertUsing((src, dest) => src ?? dest);

                cfg.CreateMap<TInsert, TEntity>().ForAllMembers(opt => opt.Condition(
                    (src, dest, srcVal) => { return srcVal != null; }));
                cfg.CreateMap<TUpdate, TEntity>().ForAllMembers(opt => opt.Condition(
                    (src, dest, srcVal, dstVal, ctx) => { return srcVal != null; }));
            });


            Mapper = config.CreateMapper();

            var configAllFields = new MapperConfiguration(cfg =>
            {
                cfg.CreateMap<TInsert, TEntity>();
                cfg.CreateMap<TUpdate, TEntity>();
            });

            AllFieldsMapper = configAllFields.CreateMapper();
        }


        [Transaction]
        public virtual async Task<TEntity> InsertAsync(TInsert request, bool saveChanges = true)
        {
            TEntity entity = CreateNewInstance();
            if (entity != null)
            {
                MapInsert(request, entity);
                var validationResult = await ValidateInsertAsync(request, entity);
                if (validationResult.HasErrors)
                {
                    throw new A.Core.Validation.ValidationException(validationResult);
                }
                if (saveChanges)
                {
                    await SaveAsync(entity);
                }
            }
            return entity;
        }

        protected virtual void MapInsert(TInsert request, TEntity entity)
        {
            Mapper.Map<TInsert, TEntity>(request, entity);
        }

        [Transaction]
        public virtual async Task<TEntity> UpdateAsync(object id, TUpdate request, bool saveChanges = true)
        {
            TEntity entity = await GetAsync(id);
            if (entity != null)
            {
                MapUpdate(request, entity);
                var validationResult = await ValidateUpdateAsync(request, entity);
                if (validationResult.HasErrors)
                {
                    throw new A.Core.Validation.ValidationException(validationResult);
                }
                if (saveChanges)
                {
                    await SaveAsync(entity);
                }
            }
            return entity;
        }

        protected virtual void MapUpdate(TUpdate request, TEntity entity)
        {
            AllFieldsMapper.Map<TUpdate, TEntity>(request, entity);
        }

        public virtual async Task<TEntity> PatchAsync(object id, TUpdate request, bool saveChanges = true)
        {
            TEntity entity = await GetAsync(id);
            if (entity != null)
            {
                MapPatch(request, entity);
                var validationResult = await ValidateUpdateAsync(request, entity);
                if (validationResult.HasErrors)
                {
                    throw new A.Core.Validation.ValidationException(validationResult);
                }
                if (saveChanges)
                {
                    await SaveAsync(entity);
                }
            }
            return entity;
        }

        protected virtual void MapPatch(TUpdate request, TEntity entity)
        {
            Mapper.Map<TUpdate, TEntity>(request, entity);
        }

        public virtual Task<A.Core.Validation.ValidationResult> ValidateInsertAsync(TInsert request, TEntity entity)
        {
            A.Core.Validation.ValidationResult result = new A.Core.Validation.ValidationResult();

            var context = new System.ComponentModel.DataAnnotations.ValidationContext(request, serviceProvider: null, items: null);
            var validationResults = new List<ValidationResult>();

            bool isValid = Validator.TryValidateObject(request, context, validationResults, true);
            if (!isValid)
            {
                validationResults.ForEach(x => { result.ResultList.Add(new A.Core.Validation.ValidationResultItem() { Key = x.MemberNames.FirstOrDefault(), Description = x.ErrorMessage }); });
            }
            return Task.FromResult(result);
        }

        public virtual Task<A.Core.Validation.ValidationResult> ValidateUpdateAsync(TUpdate request, TEntity entity)
        {
            A.Core.Validation.ValidationResult result = new A.Core.Validation.ValidationResult();

            var context = new System.ComponentModel.DataAnnotations.ValidationContext(request, serviceProvider: null, items: null);
            var validationResults = new List<ValidationResult>();

            bool isValid = Validator.TryValidateObject(request, context, validationResults, true);
            if (!isValid)
            {
                validationResults.ForEach(x => { result.ResultList.Add(new A.Core.Validation.ValidationResultItem() { Key = x.MemberNames.FirstOrDefault(), Description = x.ErrorMessage }); });
            }
            return Task.FromResult(result);
        }
    }
}
