﻿using Microsoft.AspNetCore.Identity;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Common.Services.Database
{
    public partial class AspNetUsers : IdentityUser
    {
        //[InverseProperty("User")]
        //public virtual ICollection<AspNetUserClaims> AspNetUserClaims { get; set; }
        //[InverseProperty("User")]
        //public virtual ICollection<AspNetUserLogins> AspNetUserLogins { get; set; }
        //[InverseProperty("User")]
        //public virtual ICollection<AspNetUserRoles> AspNetUserRoles { get; set; }
        //[InverseProperty("User")]
        //public virtual ICollection<AspNetUserTokens> AspNetUserTokens { get; set; }
    }
}
