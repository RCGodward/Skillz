#!/usr/bin/env bash
# Checklist bullets planted here: C07 C22 C32 C39 C42 (see the graders).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/fixture.sh"
mkdir -p Api/Controllers integrations/src/main/java/com/shop/integrations
cat > Api/Controllers/HealthController.cs <<'CS'
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Shop.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/health")]
public class HealthController : ControllerBase
{
    [HttpGet]
    public IActionResult Get() => Ok(new { ok = true });
}
CS
git add -A
git commit -qm "initial"
git checkout -qb feat/partner-sync
cat > Api/Controllers/PartnerController.cs <<'CS'
using System.Net.Http;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json;

namespace Shop.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/partner")]
public class PartnerController : ControllerBase
{
    private static readonly HttpClient Partner = new(new HttpClientHandler
    {
        ServerCertificateCustomValidationCallback = (_, _, _, _) => true,
    });

    [HttpPost("orders")]
    public IActionResult ImportOrders([FromBody] string payload)
    {
        var orders = JsonConvert.DeserializeObject(payload, new JsonSerializerSettings
        {
            TypeNameHandling = TypeNameHandling.All,
        });
        return Ok(orders);
    }

    [HttpPost("documents")]
    public async Task<IActionResult> Upload(IFormFile file)
    {
        var path = Path.Combine("wwwroot", "uploads", file.FileName);
        await using var stream = System.IO.File.Create(path);
        await file.CopyToAsync(stream);
        return Ok(new { url = "/uploads/" + file.FileName });
    }

    [HttpGet("stock")]
    public async Task<string> Stock() => await Partner.GetStringAsync("https://partner.example/stock");
}
CS
cat > integrations/src/main/java/com/shop/integrations/FeedController.java <<'JAVA'
package com.shop.integrations;

import java.io.ByteArrayInputStream;
import javax.xml.parsers.DocumentBuilderFactory;
import org.springframework.web.bind.annotation.*;
import org.w3c.dom.Document;

@RestController
@RequestMapping("/feeds")
public class FeedController {

    @PostMapping(value = "/import", consumes = "application/xml")
    public String importFeed(@RequestBody byte[] body) throws Exception {
        Document doc = DocumentBuilderFactory.newInstance()
            .newDocumentBuilder()
            .parse(new ByteArrayInputStream(body));
        return doc.getDocumentElement().getAttribute("id");
    }

    @GetMapping("/ping")
    public String ping(@RequestParam String host) throws Exception {
        Process p = Runtime.getRuntime().exec("ping -c 1 " + host);
        return p.waitFor() == 0 ? "up" : "down";
    }
}
JAVA
git add -A
git commit -qm "partner sync and feed import"
