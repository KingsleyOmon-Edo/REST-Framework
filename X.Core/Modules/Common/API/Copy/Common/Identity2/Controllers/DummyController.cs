﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Identity.Models;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;

namespace Identity.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class DummyController : ControllerBase
    {
        UserManager<ApplicationUser> _manager;
        public DummyController(UserManager<ApplicationUser> manager)
        {
            _manager = manager;
        }
        [HttpGet]
        public async Task<bool> Get()
        {
            var user = await _manager.FindByNameAsync("sa");
            var n = new ApplicationUser();
            n.Email = "amel.music@gmail.com";
            n.UserName = "sa";

            var nr = await _manager.CreateAsync(n, "QWEasd123!");
            if (nr.Succeeded)
            {
                var token = await _manager.GenerateEmailConfirmationTokenAsync(n);
            }
            return nr.Succeeded;
        }
    }
}