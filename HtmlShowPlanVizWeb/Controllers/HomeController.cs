using System;
using System.IO;
using System.Web;
using System.Web.Mvc;
using System.Xml;
using System.Xml.Xsl;

namespace HtmlShowPlanVizWeb.Controllers
{
    public class HomeController : Controller
    {
        public ActionResult Index()
        {
            return View();
        }

        [HttpPost]
        public ActionResult Upload(HttpPostedFileBase showPlanFile)
        {
            if (showPlanFile == null)
            {
                ModelState.AddModelError("", "Please specify a file");
                return View("Index");
            }

            try
            {
                var queryPlanTransform = new XslCompiledTransform();
                queryPlanTransform.Load(Server.MapPath("~/Content/showplan.xslt"));

                using (var xmlReader = XmlReader.Create(showPlanFile.InputStream))
                {
                    using (var stringWriter = new StringWriter())
                    using (var xmlWriter = XmlWriter.Create(stringWriter, queryPlanTransform.OutputSettings))
                    {
                        queryPlanTransform.Transform(xmlReader, xmlWriter);
                        return View("Index", new ShowPlanModel { ShowPlanHtml = stringWriter.ToString() });
                    }
                }
            }
            catch (Exception ex)
            {
                ModelState.AddModelError("", ex.Message);
                return View("Index");
            }
        }
    }

    public class ShowPlanModel
    {
        public string  ShowPlanHtml { get; set; }
    }
}