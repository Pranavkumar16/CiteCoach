package expo.modules.citecoachdocuments

import java.io.File
import java.io.RandomAccessFile
import java.security.MessageDigest

internal object ModelPackage {
  const val FILE_NAME = "Qwen3-1.7B-Q4_K_M.gguf"
  const val BYTES = 1107409472L
  const val SHA256 = "b139949c5bd74937ad8ed8c8cf3d9ffb1e99c866c823204dc42c0d91fa181897"
  const val URL = "https://huggingface.co/unsloth/Qwen3-1.7B-GGUF/resolve/d7f544eead698dbd1f15126ef60b45a1e1933222/Qwen3-1.7B-Q4_K_M.gguf"
  const val PREFS = "citecoach-qwen3-17b-v1"
}

internal object ModelIntegrity {
  fun hasExpectedHeaderAndSize(file:File,expectedBytes:Long):Boolean {
    if(!file.isFile || file.length()!=expectedBytes || expectedBytes<4) return false
    return try { RandomAccessFile(file,"r").use { it.readInt()==0x47475546 } } catch(_:Exception) { false }
  }
  fun verify(file:File,expectedBytes:Long,expectedSha256:String):Boolean {
    if(!hasExpectedHeaderAndSize(file,expectedBytes)) return false
    return try {
      val digest=MessageDigest.getInstance("SHA-256")
      file.inputStream().buffered(1024*1024).use { input ->
        val buffer=ByteArray(1024*1024)
        while(true) { val count=input.read(buffer);if(count<0)break;digest.update(buffer,0,count) }
      }
      digest.digest().joinToString("") { "%02x".format(it) }.equals(expectedSha256,ignoreCase=true)
    } catch(_:Exception) { false }
  }
}
