package com.yuluo.kissu.pay

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

/**
 * 支付宝支付回调Activity
 * 处理支付宝支付结果回调
 */
class AlipayActivity : FlutterActivity() {
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 处理支付宝支付结果
        val result = intent.data
        if (result != null) {
            // 将支付结果传递给Flutter端
            val intent = Intent()
            intent.putExtra("alipay_result", result.toString())
            setResult(Activity.RESULT_OK, intent)
        }
        finish()
    }
}
