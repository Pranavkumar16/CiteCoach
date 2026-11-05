package expo.modules.citecoachdocuments

import android.app.DownloadManager
import android.content.Context
import android.net.Uri
import com.tom_roush.pdfbox.android.PDFBoxResourceLoader
import com.tom_roush.pdfbox.pdmodel.PDDocument
import com.tom_roush.pdfbox.text.PDFTextStripper
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import java.io.File
import java.io.RandomAccessFile

class CiteCoachDocumentsModule : Module() {
  private fun context(): Context = appContext.reactContext ?: throw IllegalStateException("App context unavailable")
  private fun modelFile(): File = File(context().getExternalFilesDir(null), "citecoach-qwen25-05b-q4.gguf")
  private fun manager(): DownloadManager = context().getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
  private fun valid(file: File): Boolean {
    if (!file.exists() || file.length() < 300000000) return false
    return RandomAccessFile(file,"r").use { it.readInt() == 0x47475546 }
  }
  override fun definition() = ModuleDefinition {
    Name("CiteCoachDocuments")
    Events("onExtractionProgress")
    AsyncFunction("extractPdf") { uri: String ->
      PDFBoxResourceLoader.init(context())
      val file = File(Uri.parse(uri).path ?: throw IllegalArgumentException("Invalid PDF path"))
      val pages = ArrayList<Map<String,Any>>()
      PDDocument.load(file).use { document ->
        require(!document.isEncrypted) { "Password-protected PDFs are not supported. Import an unlocked copy." }
        require(document.numberOfPages <= 1500) { "Please split this PDF into files with at most 1500 pages." }
        val stripper = PDFTextStripper()
        stripper.sortByPosition = true
        for (page in 1..document.numberOfPages) {
          stripper.startPage = page
          stripper.endPage = page
          val text = stripper.getText(document).trim()
          pages.add(mapOf("page" to page, "text" to text.take(40000)))
          sendEvent("onExtractionProgress",mapOf("current" to page,"total" to document.numberOfPages))
        }
      }
      require(pages.any { (it["text"] as String).length > 40 }) { "This PDF has no selectable text. Try a text-based PDF." }
      pages
    }
    AsyncFunction("startModelDownload") {
      val file = modelFile()
      val prefs=context().getSharedPreferences("citecoach-model",Context.MODE_PRIVATE)
      val previous=prefs.getLong("id",-1)
      if (valid(file) && prefs.getBoolean("complete",false)) return@AsyncFunction -1L
      if (previous != -1L) {
        manager().query(DownloadManager.Query().setFilterById(previous)).use { cursor ->
          if(cursor.moveToFirst()) {
            val status=cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS))
            if(status == DownloadManager.STATUS_SUCCESSFUL && valid(file)) { prefs.edit().putBoolean("complete",true).apply(); return@AsyncFunction -1L }
            if(status != DownloadManager.STATUS_FAILED && status != DownloadManager.STATUS_SUCCESSFUL) return@AsyncFunction previous
          }
        }
        manager().remove(previous)
      }
      if(file.exists()) file.delete()
      val request=DownloadManager.Request(Uri.parse("https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf"))
        .setTitle("CiteCoach AI")
        .setDescription("Downloading offline AI. Your documents stay on this device.")
        .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
        .setAllowedOverMetered(true)
        .setDestinationUri(Uri.fromFile(file))
      val id=manager().enqueue(request)
      prefs.edit().putLong("id",id).putBoolean("complete",false).apply()
      id
    }
    AsyncFunction("modelStatus") {
      val file=modelFile()
      val id=context().getSharedPreferences("citecoach-model",Context.MODE_PRIVATE).getLong("id",-1)
      // Never treat a partial file with a valid header as complete.
      manager().query(DownloadManager.Query().setFilterById(id)).use { cursor ->
        if(cursor.moveToFirst()) {
          val status=cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS))
          val bytes=cursor.getLong(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR))
          val total=cursor.getLong(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_TOTAL_SIZE_BYTES))
          val reason=cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_REASON))
          val ready=status==DownloadManager.STATUS_SUCCESSFUL && valid(file)
          if(ready) context().getSharedPreferences("citecoach-model",Context.MODE_PRIVATE).edit().putBoolean("complete",true).apply()
          return@AsyncFunction mapOf("ready" to ready,"path" to file.absolutePath,"bytes" to bytes,"total" to total,"status" to status,"reason" to reason)
        }
      }
      val ready=context().getSharedPreferences("citecoach-model",Context.MODE_PRIVATE).getBoolean("complete",false) && valid(file)
      mapOf("ready" to ready,"path" to file.absolutePath,"bytes" to (if(ready) file.length() else 0L),"total" to (if(ready) file.length() else 0L),"status" to (if(ready) DownloadManager.STATUS_SUCCESSFUL else 0),"reason" to 0)
    }
    AsyncFunction("cancelModelDownload") {
      val prefs=context().getSharedPreferences("citecoach-model",Context.MODE_PRIVATE)
      val id=prefs.getLong("id",-1)
      if(id != -1L) manager().remove(id)
      prefs.edit().remove("id").remove("complete").apply()
      modelFile().delete()
    }
  }
}
