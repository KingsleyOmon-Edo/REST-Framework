﻿using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace Common.Model.Requests
{
    partial class AspNetUsersInsertRequest
    {
        [Required(AllowEmptyStrings = false)]
        public string Password { get; set; }
        public List<AspNetRolesUpsertRequest> Roles { get; set; } = new List<AspNetRolesUpsertRequest>();
    }
}
