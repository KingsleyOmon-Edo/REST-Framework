﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace A.Core.Validation
{
    /// <summary>
    /// Single validation result item. Everything is converted to this in the end
    /// </summary>
    public class ValidationResultItem
    {
        public ValidationResultItem()
        {
            Level = ValidationResultLevelEnum.Error;
        }

        public string Subkey { get; set; }
        public string Key { get; set; }
        public string Description { get; set; }
        public ValidationResultLevelEnum Level { get; set; }
        public bool AllowChaining { get; set; }

        public ValidationResultItem Then(string message, ValidationResultLevelEnum level = ValidationResultLevelEnum.Error, string key = null, string subkey = null)
        {
            if (AllowChaining)
            {
                Description = message;
                Level = level;
            }
            return this;
        }
    }

    public enum ValidationResultLevelEnum
    {
        Info = 0,
        Warning = 1,
        Error = 2
    }
}
