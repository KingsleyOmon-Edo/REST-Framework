﻿using Autofac;

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace A.Core.Interface
{
    /// <summary>
    /// Holds data for current request
    /// </summary>
    public interface IActionContext
    {
        ILifetimeScope CurrentContainer { get; set; }
        Dictionary<string,object> Data { get; set; }
    }
}
