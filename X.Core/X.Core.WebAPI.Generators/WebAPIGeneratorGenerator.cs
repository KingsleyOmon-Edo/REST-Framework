﻿using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using CodeGeneration.Roslyn;
using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;
using Microsoft.CodeAnalysis.CSharp.Syntax;

namespace X.Core.WebAPI.Generators
{
    public class WebAPIGeneratorGenerator : ICodeGenerator
    {
        private readonly AttributeData _attributeData;
        private string _interfacesPath;
        private string _interfacesNamespace;
        private string _webAPINamespace;
        private string _modelNamespace;

        public WebAPIGeneratorGenerator(AttributeData attributeData)
        {
            //Requires.NotNull(attributeData, nameof(attributeData));
            this._attributeData = attributeData;

            var mappedTo = _attributeData.NamedArguments.FirstOrDefault(x => x.Key == "InterfacesPath");
            string mappedToStr = mappedTo.Key == null ? null : mappedTo.Value.Value.ToString();
            _interfacesPath = mappedToStr;

            var interfacesNamespace = _attributeData.NamedArguments.FirstOrDefault(x => x.Key == "InterfacesNamespace");
            _interfacesNamespace = interfacesNamespace.Key == null ? "Interfaces" : interfacesNamespace.Value.Value.ToString();

            var webAPINamespace = _attributeData.NamedArguments.FirstOrDefault(x => x.Key == "WebAPINamespace");
            _webAPINamespace = interfacesNamespace.Key == null ? null : webAPINamespace.Value.Value.ToString();

            var modelNamespace = _attributeData.NamedArguments.FirstOrDefault(x => x.Key == "ModelNamespace");
            _modelNamespace = modelNamespace.Key == null ? "Model" : modelNamespace.Value.Value.ToString();
        }

        public async Task<SyntaxList<MemberDeclarationSyntax>> GenerateAsync(TransformationContext context, IProgress<Diagnostic> progress, CancellationToken cancellationToken)
        {
            var results = SyntaxFactory.List<MemberDeclarationSyntax>();
            //results.adds
            //Debugger.Launch();

            var dir = Directory.GetCurrentDirectory();
            var modelDir = dir + "/" + _interfacesPath;
            var files = Directory.GetFiles(modelDir, "*.cs", SearchOption.AllDirectories);
            StringBuilder code = new StringBuilder();
            foreach (var file in files)
            {
                var text = await File.ReadAllTextAsync(file, cancellationToken);
                code.AppendLine(text);
            }

            var tree = SyntaxFactory.ParseSyntaxTree(code.ToString());
            var root = tree.GetRoot();
           
            var services = await GenerateControllers(root, context, cancellationToken);
            results = results.AddRange(services);
            return results;
        }

        private async Task<IEnumerable<MemberDeclarationSyntax>> GenerateControllers(SyntaxNode root, TransformationContext context, CancellationToken cancellationToken)
        {
            var results = SyntaxFactory.List<MemberDeclarationSyntax>();
            //var @namespace = SyntaxFactory.NamespaceDeclaration(SyntaxFactory.ParseName("Services")).NormalizeWhitespace();
            var @namespace = SyntaxFactory.NamespaceDeclaration(SyntaxFactory.ParseName(_webAPINamespace)).NormalizeWhitespace();

            var interfaces = GetTypesWithSpecificAttribute<InterfaceDeclarationSyntax>(root, "Service");

            foreach (var classDeclarationSyntax in interfaces)
            {
                cancellationToken.ThrowIfCancellationRequested();
                var className = classDeclarationSyntax.Identifier.ValueText.TrimStart('I')
                    .Replace("Service", "");

                var controllerName = className + "Controller";

                var controller = SyntaxFactory.ClassDeclaration(controllerName);

                controller = GenerateAdditionalMethods(controllerName, classDeclarationSyntax, controller);

                controller = controller.AddModifiers(SyntaxFactory.Token(SyntaxKind.PublicKeyword), SyntaxFactory.Token(SyntaxKind.PartialKeyword));

                string keyType = "int";
                var behaviour = GetDistinctArgumentValues(classDeclarationSyntax, "Service", "Behaviour")?.FirstOrDefault();
                behaviour = behaviour ?? "EntityBehaviourEnum.Empty";
                if (behaviour == "EntityBehaviourEnum.Empty")
                {
                    controller = controller.AddBaseListTypes(
                        SyntaxFactory.SimpleBaseType(SyntaxFactory.ParseTypeName("X.Core.WebAPI.Core.BaseController")));
                }
                else if (behaviour == "EntityBehaviourEnum.Read")
                {
                    controller = controller.AddBaseListTypes(
                        SyntaxFactory.SimpleBaseType(SyntaxFactory.ParseTypeName($"X.Core.WebAPI.Core.BaseReadController<{keyType}, {_modelNamespace}.{className}, {_modelNamespace}.SearchObjects.{className}SearchObject, {_modelNamespace}.SearchObjects.{className}AdditionalSearchRequestData>")));
                }
                else if (behaviour == "EntityBehaviourEnum.CRUD")
                {
                    controller = controller.AddBaseListTypes(
                        SyntaxFactory.SimpleBaseType(SyntaxFactory.ParseTypeName($"X.Core.WebAPI.Core.BaseCRUDController<{keyType}, {_modelNamespace}.{className}, {_modelNamespace}.SearchObjects.{className}SearchObject, {_modelNamespace}.SearchObjects.{className}AdditionalSearchRequestData, {_modelNamespace}.Requests.{className}InsertRequest, {_modelNamespace}.Requests.{className}UpdateRequest>")));
                }
                else if (behaviour == "EntityBehaviourEnum.CRUDAsUpsert")
                {
                    controller = controller.AddBaseListTypes(
                        SyntaxFactory.SimpleBaseType(SyntaxFactory.ParseTypeName($"X.Core.WebAPI.Core.BaseCRUDController<{keyType}, {_modelNamespace}.{className}, {_modelNamespace}.SearchObjects.{className}SearchObject, {_modelNamespace}.SearchObjects.{className}AdditionalSearchRequestData, {_modelNamespace}.Requests.{className}UpsertRequest, {_modelNamespace}.Requests.{className}UpsertRequest>")));
                }

                //X.Core.WebAPI.Core.BaseCRUDController<int, Model.User, Model.SearchObjects.UserSearchObject, Model.SearchObjects.UserAdditionalSearchRequestData, UserUpsertRequest, UserUpsertRequest>

                @namespace = @namespace.AddMembers(controller);
            }

            results = results.Add(@namespace);
            return results;
        }

        protected virtual ClassDeclarationSyntax GenerateAdditionalMethods(string controllerName,
            InterfaceDeclarationSyntax classDeclarationSyntax, ClassDeclarationSyntax controller)
        {
            StringBuilder builder = new StringBuilder();
            builder.AppendLine(
                $"private readonly {_interfacesNamespace}.{classDeclarationSyntax.Identifier.ValueText} _mainService;");

            builder.AppendLine(
                $"public {controllerName} ({_interfacesNamespace}.{classDeclarationSyntax.Identifier.ValueText} service) : base(service)" +
                $"{{ _mainService = service; }}");
            SyntaxTree constructor = CSharpSyntaxTree.ParseText(
                builder.ToString());
            var constructorRoot = (CompilationUnitSyntax) constructor.GetRoot();
            controller = controller.AddMembers(constructorRoot.Members.ToArray());
            return controller;
        }


        protected IList<T> GetTypesWithSpecificAttribute<T>(SyntaxNode document, string attributeName) where T: TypeDeclarationSyntax
        {
            var filteredProps = document.DescendantNodes()
                .OfType<T>()
                .Where(y => y.AttributeLists.Any(z => z.Attributes.Any(u => u.Name.ToFullString() == attributeName)))
                .ToList();

            return filteredProps;
        }

        protected IList<string> GetDistinctArgumentValues(MemberDeclarationSyntax member,
            string attributeName, string argumentName)
        {

            var filteredProps = member.DescendantNodes()
                .OfType<AttributeSyntax>()
                .Where(u => u.Name.ToFullString() == attributeName)
                .SelectMany(x => x.ArgumentList.Arguments)
                .Where(x => x.NameEquals.Name.Identifier.ValueText == argumentName)
                .Select(x => x.Expression.ToFullString()).Distinct().ToList();

            return filteredProps;
        }

        protected IList<PropertyDeclarationSyntax> GetPropertiesWithSpecificAttribute(MemberDeclarationSyntax document, string attributeName)
        {
            var filteredProps = document.DescendantNodes()
                .OfType<PropertyDeclarationSyntax>()
                .Where(y => y.AttributeLists.Any(z => z.Attributes.Any(u => u.Name.ToFullString() == attributeName)))
                .ToList();

            return filteredProps;
        }

        protected IList<AttributeSyntax> GetAttributes(MemberDeclarationSyntax member, string attributeName)
        {
            //var prop = member
            //    .DescendantNodes()
            //    .OfType<PropertyDeclarationSyntax>()
            //    .SelectMany(y => y.AttributeLists)
            //    .SelectMany(y => y.Attributes)
            //    .ToList();

            //var names = prop.Select(y => y.Name.ToFullString()).ToList();
            var argumentvalue = member.DescendantNodes().OfType<AttributeSyntax>()
                .Where(x => x.Name.ToFullString() == attributeName).ToList();

            return argumentvalue;
        }

        protected string GetAttributeArgumentValue(AttributeSyntax attribute, string argumentName)
        {
            var args = attribute.ArgumentList.Arguments
                .FirstOrDefault(x => x.NameEquals.Name.Identifier.ValueText == argumentName)
                ?.Expression.ToFullString()?.Trim();

            return args;
        }
    }
}
