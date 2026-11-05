package expo.modules.citecoachdocuments

import android.app.DownloadManager
import android.content.Context
import android.net.Uri
import android.graphics.BitmapFactory
import android.media.ExifInterface
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import com.google.android.gms.tasks.Tasks
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import com.tom_roush.pdfbox.io.MemoryUsageSetting
import java.util.concurrent.TimeUnit
import kotlin.math.roundToInt
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
      // Keep PDF caches on disk and render one bounded bitmap at a time.
      val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
      var renderer: PdfRenderer? = null
      var descriptor: ParcelFileDescriptor? = null
      try {
        PDDocument.load(file, MemoryUsageSetting.setupTempFileOnly()).use { document ->
          require(!document.isEncrypted) { "Password-protected PDFs are not supported. Import an unlocked copy." }
          require(document.numberOfPages <= 1500) { "Please split this PDF into files with at most 1500 pages." }
          val stripper = PDFTextStripper()
          stripper.sortByPosition = true
          for (page in 1..document.numberOfPages) {
            stripper.startPage = page
            stripper.endPage = page
            var text = try { stripper.getText(document).trim() } catch (_: Exception) { "" }
            val needsOcr = text.count { it.isLetterOrDigit() } < 40
            if (needsOcr) {
              sendEvent("onExtractionProgress",mapOf("current" to page,"total" to document.numberOfPages,"stage" to "ocr"))
              if (renderer == null) {
                descriptor = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
                renderer = PdfRenderer(descriptor!!)
              }
              renderer!!.openPage(page-1).use { imagePage ->
                val scale = minOf(2.5f, 2200f / maxOf(imagePage.width,imagePage.height).toFloat())
                val width = maxOf(1,(imagePage.width*scale).roundToInt())
                val height = maxOf(1,(imagePage.height*scale).roundToInt())
                val bitmap = Bitmap.createBitmap(width,height,Bitmap.Config.ARGB_8888)
                try {
                  bitmap.eraseColor(Color.WHITE)
                  imagePage.render(bitmap,null,null,PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                  val result = Tasks.await(recognizer.process(InputImage.fromBitmap(bitmap,0)),45,TimeUnit.SECONDS)
                  if(result.text.count { it.isLetterOrDigit() } > text.count { it.isLetterOrDigit() }) text=result.text.trim()
                } catch (error: Exception) {
                  throw IllegalStateException("Could not read scanned page "+page+". Try a clearer copy of this PDF.",error)
                } finally { bitmap.recycle() }
              }
            }
            pages.add(mapOf("page" to page,"text" to text.take(40000),"ocr" to needsOcr))
            sendEvent("onExtractionProgress",mapOf("current" to page,"total" to document.numberOfPages,"stage" to (if(needsOcr) "ocr" else "text")))
          }
        }
      } finally {
        renderer?.close()
        descriptor?.close()
        recognizer.close()
      }
      require(pages.any { (it["text"] as String).count { c -> c.isLetterOrDigit() } > 10 }) {
        "No readable text found. Try a clearer scan or a different PDF."
      }
      pages
    }
    AsyncFunction("renderPdfPage") { uri: String, pageNumber: Int ->
      val file=File(Uri.parse(uri).path ?: throw IllegalArgumentException("Could not open this PDF."))
      val cache=File(context().cacheDir,"citecoach-preview").apply { mkdirs() }
      val preview=File(cache,file.nameWithoutExtension+"-"+file.lastModified()+"-"+pageNumber+".png")
      ParcelFileDescriptor.open(file,ParcelFileDescriptor.MODE_READ_ONLY).use { descriptor ->
        PdfRenderer(descriptor).use { pdf ->
          require(pageNumber in 1..pdf.pageCount) { "This page is not available." }
          pdf.openPage(pageNumber-1).use { page ->
            val scale=minOf(2.5f,2000f/maxOf(page.width,page.height).toFloat())
            val width=maxOf(1,(page.width*scale).roundToInt())
            val height=maxOf(1,(page.height*scale).roundToInt())
            if(!preview.exists()) {
              val bitmap=Bitmap.createBitmap(width,height,Bitmap.Config.ARGB_8888)
              val temporary=File(cache,preview.name+".tmp")
              try {
                bitmap.eraseColor(Color.WHITE)
                page.render(bitmap,null,null,PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                temporary.outputStream().use { stream -> require(bitmap.compress(Bitmap.CompressFormat.PNG,100,stream)) { "Could not display this page." } }
                require(temporary.renameTo(preview)) { "Could not save this preview. Check available storage." }
              } finally { bitmap.recycle();temporary.delete() }
            }
            // Cache only a few pages; originals remain in private document storage.
            cache.listFiles()?.filter { it.extension=="png" && it!=preview }?.sortedByDescending { it.lastModified() }?.drop(7)?.forEach { it.delete() }
            mapOf("uri" to Uri.fromFile(preview).toString(),"width" to width,"height" to height)
          }
        }
      }
    }
    AsyncFunction("readImage") { uri: String ->
      val file=File(Uri.parse(uri).path ?: throw IllegalArgumentException("Could not open this image."))
      val bounds=BitmapFactory.Options().apply { inJustDecodeBounds=true }
      BitmapFactory.decodeFile(file.absolutePath,bounds)
      require(bounds.outWidth>0 && bounds.outHeight>0) { "Could not open this image. Try JPG or PNG." }
      var sample=1
      while(maxOf(bounds.outWidth,bounds.outHeight)/sample>2200) sample*=2
      val bitmap=BitmapFactory.decodeFile(file.absolutePath,BitmapFactory.Options().apply { inSampleSize=sample })
        ?: throw IllegalArgumentException("Could not open this image. Try JPG or PNG.")
      val recognizer=TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
      val orientation=try { ExifInterface(file.absolutePath).getAttributeInt(ExifInterface.TAG_ORIENTATION,ExifInterface.ORIENTATION_NORMAL) } catch (_: Exception) { ExifInterface.ORIENTATION_NORMAL }
      val rotation=when(orientation) { ExifInterface.ORIENTATION_ROTATE_90 -> 90; ExifInterface.ORIENTATION_ROTATE_180 -> 180; ExifInterface.ORIENTATION_ROTATE_270 -> 270; else -> 0 }
      sendEvent("onExtractionProgress",mapOf("current" to 1,"total" to 1,"stage" to "ocr"))
      val task=recognizer.process(InputImage.fromBitmap(bitmap,rotation))
      try {
        val text=Tasks.await(task,45,TimeUnit.SECONDS).text.trim()
        listOf(mapOf("page" to 1,"text" to text.take(40000),"label" to "Image","ocr" to true))
      } finally {
        if(task.isComplete) { bitmap.recycle();recognizer.close() }
        else task.addOnCompleteListener { bitmap.recycle();recognizer.close() }
      }
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
