using A.Core.Interface;
using A.Core.Model;
using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using AutoMapper;
using System.ComponentModel.DataAnnotations;
using AutoMapper.Internal;
using A.Core;
using A.Core.Interceptors;
using Autofac.Extras.DynamicProxy;

namespace $rootnamespace$.Core //DD
{

    public partial class BaseEFBasedCRUDService<TEntity, TSearchObject, TSearchAdditionalData, TInsert, TUpdate, TDBContext, TDbEntity> : BaseEFBasedReadService<TEntity, TSearchObject, TSearchAdditionalData, TDBContext, TDbEntity>, ICRUDService<TEntity, TSearchObject, TSearchAdditionalData, TInsert, TUpdate>
        where TEntity : class, new()
        where TDbEntity : class, new()
        where TSearchAdditionalData : BaseAdditionalSearchRequestData, new()
        where TDBContext : DbContext, new()
        where TSearchObject : BaseSearchObject<TSearchAdditionalData>, new()
    {
        // ReSharper disable once StaticMemberInGenericType
        public static IMapper Mapper { get; set; }
        static BaseEFBasedCRUDService()
        {

            var config = new MapperConfiguration(cfg =>
            {
                cfg.CreateMap<TInsert, TDbEntity>().ForAllMembers(opt => opt.Condition(
                    (src, dest, srcVal) => { return srcVal != null; }));
                cfg.CreateMap<TUpdate, TDbEntity>().ForAllMembers(opt => opt.Condition(
                     (src, dest, srcVal) => { return srcVal != null; }));
            });


            Mapper = config.CreateMapper();
        }

        [Transaction]
        public virtual TEntity Insert(TInsert request, bool saveChanges = true)
        {
            TDbEntity entity = CreateNewInstance();
            if (entity != null)
            {
                Mapper.Map<TInsert, TDbEntity>(request, entity);
                var validationResult = ValidateInsert(request, entity);
                if (validationResult.HasErrors)
                {
                    throw new A.Core.Validation.ValidationException(validationResult);
                }
                Entity.Attach(entity);
                Context.Entry(entity).State = EntityState.Added;
                if (saveChanges)
                {
                    Save(entity);
                }
            }
            return GlobalMapper.Mapper.Map<TEntity>(entity);
        }

        [Transaction]
        public virtual TEntity Update(object id, TUpdate request, bool saveChanges = true)
        {
            var entity = GetByIdInternal(id);
            if (entity != null)
            {
                Mapper.Map<TUpdate, TDbEntity>(request, entity);
                var validationResult = ValidateUpdate(request, entity);
                if (validationResult.HasErrors)
                {
                    throw new A.Core.Validation.ValidationException(validationResult);
                }
                Entity.Attach(entity);
                Context.Entry(entity).State = EntityState.Modified;
                if (saveChanges)
                {
                    Save(entity);
                }
            }
            return GlobalMapper.Mapper.Map<TEntity>(entity);
        }

        public virtual A.Core.Validation.ValidationResult ValidateInsert(TInsert request, TDbEntity entity)
        {
            A.Core.Validation.ValidationResult result = new A.Core.Validation.ValidationResult();

            var context = new System.ComponentModel.DataAnnotations.ValidationContext(request, serviceProvider: null, items: null);
            var validationResults = new List<ValidationResult>();

            bool isValid = Validator.TryValidateObject(request, context, validationResults, true);
            if (!isValid)
            {
                validationResults.ForEach(x => { result.ResultList.Add(new A.Core.Validation.ValidationResultItem() { Key = x.MemberNames.FirstOrDefault(), Description = x.ErrorMessage }); });
            }
            return result;
        }

        public virtual A.Core.Validation.ValidationResult ValidateUpdate(TUpdate request, TDbEntity entity)
        {
            A.Core.Validation.ValidationResult result = new A.Core.Validation.ValidationResult();

            var context = new System.ComponentModel.DataAnnotations.ValidationContext(request, serviceProvider: null, items: null);
            var validationResults = new List<ValidationResult>();

            bool isValid = Validator.TryValidateObject(request, context, validationResults, true);
            if (!isValid)
            {
                validationResults.ForEach(x => { result.ResultList.Add(new A.Core.Validation.ValidationResultItem() { Key = x.MemberNames.FirstOrDefault(), Description = x.ErrorMessage }); });
            }
            return result;
        }
    }
}
