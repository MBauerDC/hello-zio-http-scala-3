import zhttp.http._
import zhttp.service.Server
import zio._

object WebApp extends ZIOAppDefault {

  val app = Http.text("hello, world")

  def run = Server.start(8080, app).exitCode

}
