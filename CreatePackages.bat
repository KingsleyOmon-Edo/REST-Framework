ECHO Creating packages!
cd A.Core.Interfaces.Nuget
nuget pack
cd ..
cd A.Core.Model.Nuget
nuget pack
cd ..
cd A.Core.Nuget
nuget pack
cd ..
cd A.Core.Services.Nuget
nuget pack
cd ..
cd A.Core.WebAPI.Nuget
nuget pack
cd ..
cd A.Core.Scheduler.Nuget
nuget pack
cd ..
cd A.Core.RESTClient.Nuget
nuget pack
cd ..
cd A.Core.Messaging.Nuget
nuget pack
cd ..
cd A.Core.Scripting.Nuget
nuget pack
cd ..
cd Modules\PermissionModule\Src\A.Core.PermissionModule.Services.Nuget
nuget pack
cd ..
cd ..
cd ..
cd ..